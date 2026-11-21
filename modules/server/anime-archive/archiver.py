#!/usr/bin/env python3
"""追番归档器。

职责：从 aria2 领取已完成的下载任务 → 按模板重命名 → 上传到 OpenList 目标 →
按大小校验 → 删除本地文件 → 记账并刷新云盘索引。

设计要点（详见 docs/anime-archive-design.md）：
- 只使用 Python 标准库，大文件传输交给 curl 子进程，避免在 2 GiB 内存的机器上吃内存。
- 上传成功且校验通过才删除本地；失败则保留文件并按指数退避重试。
- 月度下载预算、磁盘水位、命名失败清单都在这里落地。
"""

import contextlib
import fcntl
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from datetime import UTC, datetime
from pathlib import Path

GiB = 1024**3
# 小于这个体积的“正片”基本只能是未下载完成的占位文件。
MIN_VIDEO_BYTES = 1 * 1024 * 1024

VIDEO_EXTS = {".mkv", ".mp4", ".avi", ".ts", ".m2ts", ".flv", ".webm", ".mov"}
SUB_EXTS = {".ass", ".ssa", ".srt", ".vtt", ".sub", ".idx", ".sup"}
LANG_TAGS = {"chs", "cht", "sc", "tc", "chi", "zh", "zh-cn", "zh-hans", "zh-hant", "jpn", "jp", "eng"}

ARIA2_FIELDS = [
    "gid",
    "status",
    "totalLength",
    "completedLength",
    "dir",
    "files",
    "bittorrent",
    "followedBy",
    "errorCode",
    "infoHash",
]

cfg = {}


# --------------------------------------------------------------------------- 基础设施


def log(level, event, **fields):
    record = {
        "ts": datetime.now(UTC).isoformat(timespec="seconds"),
        "level": level,
        "event": event,
    }
    record.update(fields)
    print(json.dumps(record, ensure_ascii=False), flush=True)


def die(message):
    log("error", "fatal", message=message)
    sys.exit(1)


def read_secret(path):
    try:
        return Path(path).read_text(encoding="utf-8").strip()
    except OSError as exc:
        die(f"读取密钥失败：{path}：{exc}")


ALLOWED_SCHEMES = {"http", "https"}


def open_url(request, timeout):
    """只允许 http(s)，避免 urlopen 被指向 file: 等本地协议。"""
    scheme = urllib.parse.urlparse(request.full_url).scheme
    if scheme not in ALLOWED_SCHEMES:
        raise ValueError(f"不支持的协议：{scheme}")
    return urllib.request.urlopen(request, timeout=timeout)  # noqa: S310


def http_json(url, payload, headers=None, timeout=30, method="POST"):
    data = None if payload is None else json.dumps(payload).encode()
    request = urllib.request.Request(url, data=data, method=method)  # noqa: S310 - 已校验协议
    request.add_header("Content-Type", "application/json")
    for key, value in (headers or {}).items():
        request.add_header(key, value)
    with open_url(request, timeout) as response:
        body = response.read()
    try:
        return json.loads(body or b"{}")
    except ValueError as exc:
        raise RuntimeError(f"响应不是合法 JSON：{body[:200]!r}") from exc


def hashlib_file(path):
    digest = hashlib.sha256()
    try:
        with open(path, "rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
    except OSError as exc:
        raise RuntimeError(f"无法读取文件 {path}：{exc}") from exc
    return digest.hexdigest()


# --------------------------------------------------------------------------- aria2


class Aria2:
    def __init__(self, rpc_url, secret):
        self.rpc_url = rpc_url
        self.secret = secret

    def call(self, method, *params):
        payload = {
            "jsonrpc": "2.0",
            "id": "anime-archive",
            "method": method,
            "params": [f"token:{self.secret}", *params],
        }
        result = http_json(self.rpc_url, payload, timeout=30)
        if "error" in result:
            raise RuntimeError(f"{method} 失败：{result['error']}")
        return result["result"]

    def completed(self):
        """返回 complete 状态的任务；磁力链元数据占位任务被跳过。"""
        torrents = []
        try:
            torrents.extend(self.call("aria2.tellStopped", 0, 1000, ARIA2_FIELDS))
        except Exception as exc:  # noqa: BLE001 - 单个接口失败不应中断整轮
            log("warning", "aria2_tell_stopped_failed", error=str(exc))
        for method, args in (
            ("aria2.tellActive", (ARIA2_FIELDS,)),
            ("aria2.tellWaiting", (0, 1000, ARIA2_FIELDS)),
        ):
            try:
                torrents.extend(self.call(method, *args))
            except Exception as exc:  # noqa: BLE001
                log("warning", "aria2_query_failed", method=method, error=str(exc))

        return [
            torrent
            for torrent in torrents
            if torrent.get("status") == "complete" and not torrent.get("followedBy")
        ]

    def all_files(self):
        """aria2 记录里出现过的所有文件路径（含下载中与已停止）。"""
        paths = set()
        for method, args in (
            ("aria2.tellActive", (["files"],)),
            ("aria2.tellWaiting", (0, 1000, ["files"])),
            ("aria2.tellStopped", (0, 1000, ["files"])),
        ):
            try:
                for task in self.call(method, *args):
                    for entry in task.get("files") or []:
                        if entry.get("path"):
                            paths.add(entry["path"])
            except Exception as exc:  # noqa: BLE001 - 单个接口失败不应中断整轮
                log("warning", "aria2_query_failed", method=method, error=str(exc))
        return paths

    def remove(self, gid):
        self.call("aria2.removeDownloadResult", gid)

    def pause_all(self):
        self.call("aria2.pauseAll")


# --------------------------------------------------------------------------- OpenList


class OpenList:
    def __init__(self, base_url, token):
        self.base_url = base_url.rstrip("/")
        self.token = token

    def _headers(self):
        return {"Authorization": self.token}

    def stat(self, remote_path):
        """返回远程文件信息；不存在返回 None。"""
        payload = {"path": remote_path, "password": ""}
        try:
            result = http_json(self.base_url + "/api/fs/get", payload, headers=self._headers(), timeout=60)
        except urllib.error.HTTPError as exc:
            if exc.code in (404, 500):
                return None
            raise
        if result.get("code") != 200:
            return None
        data = result.get("data") or {}
        if data.get("is_dir"):
            return None
        return data

    def list_dir(self, remote_path):
        """列出目录内容；目录不存在或不是目录时返回 None。"""
        entries = []
        page = 1
        while True:
            payload = {
                "path": remote_path,
                "password": "",
                "page": page,
                "per_page": 200,
                "refresh": False,
            }
            result = http_json(
                self.base_url + "/api/fs/list", payload, headers=self._headers(), timeout=60
            )
            if result.get("code") != 200:
                return None
            data = result.get("data") or {}
            content = data.get("content") or []
            entries.extend(content)
            total = int(data.get("total") or 0)
            if len(content) < 200 or page * 200 >= total:
                break
            page += 1
        return entries

    def put(self, local_path, remote_path, timeout=3600):
        """用 curl 流式上传，避免把文件读进内存。"""
        size = os.path.getsize(local_path)
        command = [
            "curl",
            "-sS",
            "--fail-with-body",
            "-X",
            "PUT",
            "-T",
            str(local_path),
            "-H",
            f"Authorization: {self.token}",
            "-H",
            "File-Path: " + urllib.parse.quote(remote_path, safe="/"),
            "-H",
            f"Content-Length: {size}",
            "-H",
            "Content-Type: application/octet-stream",
            "-H",
            "As-Task: false",
            "--connect-timeout",
            "20",
            "--max-time",
            str(timeout),
            self.base_url + "/api/fs/put",
        ]
        completed = subprocess.run(command, capture_output=True, text=True, check=False)
        if completed.returncode != 0:
            raise RuntimeError(f"curl 退出码 {completed.returncode}：{completed.stderr.strip()[:400]}")
        try:
            result = json.loads(completed.stdout or "{}")
        except json.JSONDecodeError:
            raise RuntimeError(f"上传响应无法解析：{completed.stdout.strip()[:400]}") from None
        if result.get("code") != 200:
            raise RuntimeError(f"上传失败 code={result.get('code')} message={result.get('message')}")

    def verify(self, local_path, remote_path, mode="size"):
        data = self.stat(remote_path)
        if data is None:
            return False, "远程文件不存在"
        size = os.path.getsize(local_path)
        if data.get("size") != size:
            return False, f"大小不符：本地 {size} / 远程 {data.get('size')}"
        if mode != "hash":
            return True, "size 一致"

        raw_url = data.get("raw_url")
        if not raw_url:
            return False, "hash 模式缺少 raw_url"
        local_digest = hashlib_file(local_path)
        tmp = Path(cfg["stateDir"]) / "verify.tmp"
        try:
            subprocess.run(
                ["curl", "-sS", "--fail", "-L", "-o", str(tmp), raw_url],
                capture_output=True,
                text=True,
                check=True,
                timeout=3600,
            )
            remote_digest = hashlib_file(tmp)
        finally:
            tmp.unlink(missing_ok=True)
        if local_digest != remote_digest:
            return False, f"内容不一致：{local_digest[:12]} / {remote_digest[:12]}"
        return True, "hash 一致"


# --------------------------------------------------------------------------- 命名


SXXEXX = re.compile(r"[Ss](\d{1,2})[Ee](\d{1,4})")
EPISODE_PATTERNS = [
    re.compile(r"第\s*(\d{1,4})\s*[话話集]"),
    re.compile(r"\[\s*(\d{1,4})(?:v\d)?\s*\]"),
    re.compile(r"-\s*(\d{1,4})(?:v\d)?(?=[\s.\[]|$)"),
    re.compile(r"\b[Ee][Pp]?\.?\s*(\d{1,4})\b"),
]
BRACKET_GROUP = re.compile(r"\[([^\]]*)\]")
# 季号补充：中文「第二季」与英文「S2 / Season 2」。
CN_SEASON = re.compile(r"第\s*([一二三四五六七八九十\d]+)\s*[季期]")
EN_SEASON = re.compile(r"(?i)(?:\bS|\bSeason\s?)(\d{1,2})(?![0-9pP])")
CN_DIGITS = {"一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6, "七": 7, "八": 8, "九": 9, "十": 10}
ROUND_GROUP = re.compile(r"\([^)]*\)")
EPISODE_TAIL = re.compile(r"\s*-\s*\d{1,4}(?:v\d)?\b.*$")
CN_EPISODE = re.compile(r"第\s*\d{1,4}\s*[话話集]")
TAG_HINT = re.compile(
    r"(?i)(\d{3,4}p|x26[45]|hevc|avc|aac|flac|opus|web-?dl|webrip|bluray|bd ?rip|10bit|8bit"
    r"|chs|cht|sc|tc|jpn|eng|mp4|mkv|av1|vp9|baha|bilibili|amzn|简|繁|字幕|内嵌|外挂|合集|全集)"
)
QUALITY_TAGS = re.compile(
    r"(?i)\b(1080p|720p|2160p|480p|web-?dl|webrip|bluray|bdrip|hevc|x265|x264|avc|aac|flac|10bit|8bit)\b"
)
SKIP_EXTS = {".aria2", ".torrent", ".tmp", ".parts"}
BAD_CHARS = re.compile(r'[?*:<>|"/\\\x00-\x1f]')


def sanitize(name):
    """去掉文件系统与 OpenList 都不接受的字符，并折叠空白。"""
    cleaned = BAD_CHARS.sub(" ", unicodedata.normalize("NFC", name))
    cleaned = re.sub(r"\s+", " ", cleaned).strip(" .")
    return cleaned or "unnamed"


def looks_like_tag(text):
    """判断方括号内容是不是编码/语言/来源之类的标签。"""
    value = text.strip()
    if not value:
        return True
    if re.fullmatch(r"(?i)(?:ep?)?\d{1,4}(?:v\d)?", value):
        return True
    return bool(TAG_HINT.search(value))


CJK_BRACKET = re.compile(r"【([^】]*)】")
# 「10月新番」「★…★」这类季节性噪声不应被当成作品名。
SEASONAL_NOISE = re.compile(r"新番|旧番|月番|完结|★|☆")


def looks_like_noise(text):
    if SEASONAL_NOISE.search(text):
        return True
    return len(re.sub(r"\W", "", text)) < 2


def normalize_brackets(name):
    """把全角【】统一成半角[]，幻樱/诸神等字幕组习惯用全角括号。"""
    return CJK_BRACKET.sub(r"[\1]", name)


def title_from_name(name):
    """优先用方括号外的自由文本作标题；整个名字都被方括号包住时退回归纳法。"""
    name = normalize_brackets(name)
    free = BRACKET_GROUP.sub(" ", name)
    free = ROUND_GROUP.sub(" ", free)
    free = SXXEXX.sub(" ", free)
    free = CN_EPISODE.sub(" ", free)
    free = EPISODE_TAIL.sub(" ", free)
    free = QUALITY_TAGS.sub(" ", free)
    free = free.split("/")[0]  # 「中文名 / Romaji」只留中文名
    free = re.sub(r"[\s\-–_]+", " ", free).strip()
    title = sanitize(free)
    if title != "unnamed" and not looks_like_noise(free):
        return title

    groups = BRACKET_GROUP.findall(name)
    candidates = [group for group in groups[1:] if not looks_like_tag(group)]
    if candidates:
        # 全被方括号包住时，最长的非标签段通常就是作品名。
        longest = max(candidates, key=len)
        return sanitize(longest.split("/")[0])
    return sanitize(groups[0]) if groups else sanitize(name)


def parse_release(release_name):
    """从发布名里抠出标题、季、集；抠不到的项返回 None。"""
    name = normalize_brackets(release_name)
    for suffix in (".mkv", ".mp4", ".avi", ".ts", ".m2ts", ".torrent"):
        if name.lower().endswith(suffix):
            name = name[: -len(suffix)]

    season = None
    episode = None
    matched = SXXEXX.search(name)
    if matched:
        season, episode = int(matched.group(1)), int(matched.group(2))
    else:
        for pattern in EPISODE_PATTERNS:
            found = pattern.search(name)
            if found:
                episode = int(found.group(1))
                break
        season = season_from_name(name)

    return title_from_name(name), season, episode


def season_from_name(name):
    """从「第二季」「S2」「Season 2」里取季号，取不到返回 None。"""
    found = CN_SEASON.search(name)
    if found:
        value = found.group(1)
        if value.isdigit():
            return int(value)
        if value in CN_DIGITS:
            return CN_DIGITS[value]
        if value.startswith("十"):
            return 10 + CN_DIGITS.get(value[1:], 0)
    found = EN_SEASON.search(name)
    if found:
        return int(found.group(1))
    return None


def ab_lookup(ab_url, release_name):
    """向 AutoBangumi 查询季集元数据；无匹配或接口不可用返回 None。"""
    if not ab_url:
        return None
    for endpoint in ("/api/v1/bangumi/all", "/api/v1/bangumi/"):
        try:
            payload = http_json(ab_url.rstrip("/") + endpoint, None, method="GET", timeout=15)
        except Exception as exc:  # noqa: BLE001 - 元数据是可选增强，失败即退回正则
            log("warning", "ab_lookup_failed", endpoint=endpoint, error=str(exc))
            continue
        items = payload.get("data") if isinstance(payload, dict) else payload
        if isinstance(items, dict):
            items = items.get("bangumi") or items.get("items") or []
        if not isinstance(items, list):
            continue
        for item in items:
            if not isinstance(item, dict):
                continue
            candidates = [item.get(key) for key in ("title_raw", "official_title", "title_en", "title")]
            if not any(isinstance(text, str) and text and text in release_name for text in candidates):
                continue
            title = item.get("official_title") or item.get("title_raw") or item.get("title")
            if not title:
                continue
            try:
                season = int(item.get("season") or 1)
            except (TypeError, ValueError):
                season = 1
            try:
                episode = int(item["episode"]) if item.get("episode") is not None else None
            except (TypeError, ValueError):
                episode = None
            return sanitize(str(title)), season, episode
    return None


def lang_suffix(path):
    parts = Path(path).name.lower().split(".")
    for part in reversed(parts[:-1]):
        if part in LANG_TAGS:
            return "." + part
    return ""


def build_name(title, season, episode, video_path, subtitle=False):
    ext = Path(video_path).suffix
    if subtitle:
        ext = lang_suffix(video_path) + ext
    return sanitize(
        cfg["naming"]["template"].format(title=title, season=season, episode=episode, ext=ext)
    )


def extra_name(title, path):
    """把附件命名成「番名 + 去掉分组/标签的原始名」。"""
    stem = normalize_brackets(path.name)
    stem = BRACKET_GROUP.sub(" ", stem)
    stem = ROUND_GROUP.sub(" ", stem)
    stem = re.sub(r"\s+", " ", stem).strip(" -_.")
    lowered = stem.lower()
    if title and title.lower() in lowered:
        stem = stem[lowered.index(title.lower()) + len(title) :]
    stem = stem.lstrip(" -_.")
    suffix = path.suffix
    if suffix and stem.lower().endswith(suffix.lower()):
        stem = stem[: -len(suffix)]
    stem = sanitize(stem)
    if stem in ("", "unnamed"):
        stem = "extra"
    return sanitize(f"{title} {stem}{suffix}")


def is_attachment(path):
    """字体包、封面等随种子发布的非视频文件。"""
    if path.name.startswith("."):
        return False
    return path.suffix.lower() not in SKIP_EXTS


def torrent_release(torrent):
    info = (torrent.get("bittorrent") or {}).get("info") or {}
    return info.get("name") or Path(torrent.get("dir", "")).name or torrent["gid"]


def plan_files(torrent):
    """把种子内选中的文件映射成目标相对路径。返回 (plan, error)。"""
    release = torrent_release(torrent)
    files = [entry for entry in torrent.get("files", []) if entry.get("selected") in ("true", True)]
    videos = [entry for entry in files if Path(entry["path"]).suffix.lower() in VIDEO_EXTS]
    if not videos:
        return None, "没有可用的视频文件"

    meta = ab_lookup(cfg.get("abUrl"), release) if cfg["naming"]["abMetadata"] else None
    if meta is None:
        title, season, episode = parse_release(release)
        meta = (title, season or 1, episode)
    base_title, base_season, base_episode = meta

    plan = []
    extras_dir = cfg["naming"].get("extraDir", "Extra")
    videos_plan = []
    subs_plan = []
    extra_plan = []
    for entry in files:
        path = Path(entry["path"])
        suffix = path.suffix.lower()
        is_sub = suffix in SUB_EXTS
        is_video = suffix in VIDEO_EXTS
        if not is_video and not is_sub and not is_attachment(path):
            continue

        title, season, episode = base_title, base_season, base_episode
        if is_sub:
            # 字幕跟随同目录视频；文件名自带集数时以字幕为准
            _, sub_season, sub_episode = parse_release(path.name)
            sibling = next((video for video in videos if Path(video["path"]).parent == path.parent), None)
            if sibling is not None:
                _, sib_season, sib_episode = parse_release(Path(sibling["path"]).name)
                sub_season = sub_season if sub_season is not None else sib_season
                sub_episode = sub_episode if sub_episode is not None else sib_episode
            season = sub_season if sub_season is not None else season
            episode = sub_episode if sub_episode is not None else episode
        elif is_video and len(videos) > 1:
            # 合集：每集各自解析
            _, file_season, file_episode = parse_release(path.name)
            season = file_season if file_season is not None else season
            episode = file_episode if file_episode is not None else episode

        if (is_video or is_sub) and episode is None:
            return None, f"无法确定集数：{path.name}"

        season_dir = cfg["naming"]["seasonDir"].format(season=season)
        if is_video:
            rel = f"{title}/{season_dir}/{build_name(title, season, episode, str(path))}"
            bucket = videos_plan
        elif is_sub:
            # 字幕与字体包等非视频文件统一放进季目录下的独立子目录
            filename = build_name(title, season, episode, str(path), subtitle=True)
            rel = f"{title}/{season_dir}/{extras_dir}/{filename}"
            bucket = subs_plan
        else:
            rel = f"{title}/{season_dir}/{extras_dir}/{extra_name(title, path)}"
            bucket = extra_plan

        bucket.append(
            {
                "src": entry["path"],
                "rel": rel,
                "size": int(entry.get("length") or 0),
                "subtitle": is_sub,
                "video": is_video,
                "title": title,
                "season": season,
                "episode": episode,
            }
        )

    if not videos_plan:
        return None, "没有可用的视频文件"

    # 视频在前，保证 head 始终是正片；附件重名时追加序号，避免互相覆盖
    plan = videos_plan + subs_plan + extra_plan
    seen = {}
    for item in plan:
        if item["rel"] not in seen:
            seen[item["rel"]] = 1
            continue
        seen[item["rel"]] += 1
        path = Path(item["rel"])
        item["rel"] = str(path.with_name(f"{path.stem} ({seen[item['rel']]}){path.suffix}"))
    return plan, None


# --------------------------------------------------------------------------- 状态


def state_path():
    return Path(cfg["stateDir"]) / "state.json"


def load_state():
    path = state_path()
    if not path.exists():
        return {"entries": {}, "budget": {}, "lastNotify": None}
    try:
        state = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        log("warning", "state_load_failed", error=str(exc))
        return {"entries": {}, "budget": {}, "lastNotify": None}
    state.setdefault("entries", {})
    state.setdefault("budget", {})
    state.setdefault("lastNotify", None)
    return state


def save_state(state):
    path = state_path()
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(state, ensure_ascii=False, indent=2), encoding="utf-8")
    os.replace(tmp, path)


def month_key():
    return datetime.now(UTC).strftime("%Y-%m")


def disk_free():
    return shutil.disk_usage(cfg["downloadRoot"]).free


def write_status(state, hold, pending):
    payload = {
        "ts": datetime.now(UTC).isoformat(timespec="seconds"),
        "hold": hold,
        "pending": pending,
        "month": month_key(),
        "monthDownloadGiB": round(state["budget"].get(month_key(), 0) / GiB, 2),
        "budgetGiB": cfg["monthlyDownloadBudgetGiB"],
        "diskFreeGiB": round(disk_free() / GiB, 2),
        "entries": len(state["entries"]),
        "dryRun": cfg["dryRun"],
    }
    path = Path(cfg["stateDir"]) / "status.json"
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def notify(state, reason):
    """hold 状态发生变化时调用一次外部通知命令。"""
    if state.get("lastNotify") == reason:
        return
    state["lastNotify"] = reason
    command = cfg.get("notifyCommand") or []
    if not command:
        log("warning", "notify_skipped", reason=reason)
        return
    try:
        subprocess.run([*command, reason], check=False, timeout=30)
        log("info", "notified", reason=reason)
    except Exception as exc:  # noqa: BLE001 - 通知失败不影响归档
        log("warning", "notify_failed", error=str(exc))


# --------------------------------------------------------------------------- 索引


def render_index(state):
    rows = [entry for entry in state["entries"].values() if entry.get("status") == "done"]
    rows.sort(key=lambda item: (item.get("title", ""), int(item.get("season") or 1), int(item.get("episode") or 0)))
    lines = [
        "| 番剧 | 季 | 集 | 大小 | 归档时间 | 原始种子名 |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for entry in rows:
        size_bytes = entry.get("bytes", 0)
        size_text = (
            f"{size_bytes / GiB:.2f} GiB" if size_bytes >= GiB else f"{size_bytes / 1024**2:.0f} MiB"
        )
        lines.append(
            "| {title} | {season:02d} | {episode:02d} | {size} | {at} | {release} |".format(
                title=entry.get("title", ""),
                season=int(entry.get("season") or 1),
                episode=int(entry.get("episode") or 0),
                size=size_text,
                at=entry.get("archivedAt", ""),
                release=str(entry.get("release", "")).replace("|", "/"),
            )
        )
    return "\n".join(lines) + "\n"


def render_unnamed(state):
    rows = [entry for entry in state["entries"].values() if entry.get("unnamed")]
    rows.sort(key=lambda item: item.get("archivedAt", ""))
    lines = [
        "| 归档时间 | 原始种子名 | 失败原因 | 云盘落点 |",
        "| --- | --- | --- | --- |",
    ]
    for entry in rows:
        lines.append(
            "| {at} | {release} | {reason} | {where} |".format(
                at=entry.get("archivedAt", ""),
                release=str(entry.get("release", "")).replace("|", "/"),
                reason=str(entry.get("reason", "")).replace("|", "/"),
                where=entry.get("where", ""),
            )
        )
    return "\n".join(lines) + "\n"


def flush_index(state, openlist):
    index_cfg = cfg["index"]
    if not index_cfg["enable"] or cfg["dryRun"]:
        return
    staging = Path(cfg["stateDir"])
    if index_cfg.get("path"):
        local = staging / "_archive-index.md"
        local.write_text(render_index(state), encoding="utf-8")
        openlist.put(local, index_cfg["path"])
    if index_cfg.get("unnamedPath"):
        local = staging / "_unnamed.md"
        local.write_text(render_unnamed(state), encoding="utf-8")
        openlist.put(local, index_cfg["unnamedPath"])
    state["indexFlushedAt"] = datetime.now(UTC).isoformat(timespec="seconds")
    log("info", "index_flushed")


# --------------------------------------------------------------------------- 番剧库总览

EPISODE_PATTERN = re.compile(r"[Ss](\d{1,2})[Ee](\d{2,3})")
SEASON_PATTERN = re.compile(r"(\d{1,3})")
LIBRARY_SKIP = {"README.md", "_archive-index.md", "_unnamed.md"}


def human_size(size_bytes):
    if size_bytes >= GiB:
        return f"{size_bytes / GiB:.2f} GiB"
    if size_bytes >= 1024**2:
        return f"{size_bytes / 1024**2:.0f} MiB"
    return f"{size_bytes / 1024:.0f} KiB"


def episode_of(name):
    matched = EPISODE_PATTERN.search(name)
    return int(matched.group(2)) if matched else None


def season_number_of(name):
    matched = SEASON_PATTERN.search(name or "")
    return int(matched.group(1)) if matched else None


def cell(value):
    """markdown 表格里不能出现裸竖线。"""
    return str(value).replace("|", "／")


def season_stats(files):
    videos = [item for item in files if Path(item.get("name", "")).suffix.lower() in VIDEO_EXTS]
    episodes = {episode_of(item.get("name", "")) for item in videos}
    episodes.discard(None)
    return {
        "episodes": len(episodes) or len(videos),
        "videos": len(videos),
        "size": sum(int(item.get("size") or 0) for item in files),
        "updated": max((item.get("modified") or "" for item in files), default=""),
    }


def expand_dirs(openlist, path, items):
    """把季目录下的子目录（如 Extra/）展开进统计列表，否则附件体积会被漏算。"""
    expanded = list(items)
    for item in items:
        if not item.get("is_dir"):
            continue
        name = item.get("name", "")
        expanded.extend(openlist.list_dir(f"{path}/{name}") or [])
    return expanded


def scan_library(openlist, root):
    """扫描云端根目录，统计每部番剧的季/集/体积。"""
    titles = []
    for entry in sorted(openlist.list_dir(root) or [], key=lambda item: item.get("name", "")):
        name = entry.get("name", "")
        if not entry.get("is_dir") or name.startswith("_") or name in LIBRARY_SKIP:
            continue
        children = openlist.list_dir(f"{root}/{name}") or []
        seasons = []
        loose = []
        for child in children:
            child_name = child.get("name", "")
            if child.get("is_dir"):
                season_path = f"{root}/{name}/{child_name}"
                seasons.append(
                    {
                        "name": child_name,
                        "number": season_number_of(child_name),
                        **season_stats(
                            expand_dirs(openlist, season_path, openlist.list_dir(season_path) or [])
                        ),
                    }
                )
            elif Path(child_name).suffix.lower() in VIDEO_EXTS:
                loose.append(child)
        if loose:
            seasons.append({"name": "未分季", "number": 999, **season_stats(loose)})
        seasons.sort(key=lambda row: row["number"] if row["number"] is not None else 998)
        titles.append({"title": name, "seasons": seasons})
    titles.sort(key=lambda item: item["title"])
    return titles


def render_library(titles, root):
    now = datetime.now().astimezone().strftime("%Y-%m-%d %H:%M %z")
    total_seasons = sum(len(title["seasons"]) for title in titles)
    total_episodes = sum(season["episodes"] for title in titles for season in title["seasons"])
    total_size = sum(season["size"] for title in titles for season in title["seasons"])
    lines = [
        "# 番剧库总览",
        "",
        f"- 扫描目录：`{root}`",
        f"- 最后更新：{now}",
        f"- 合计：**{len(titles)}** 部 / **{total_seasons}** 季 / **{total_episodes}** 集 / {human_size(total_size)}",
        "",
        "| 番剧 | 季数 | 集数 | 体积 |",
        "| --- | ---: | ---: | ---: |",
    ]
    for title in titles:
        episodes = sum(season["episodes"] for season in title["seasons"])
        size = sum(season["size"] for season in title["seasons"])
        lines.append(
            f"| {cell(title['title'])} | {len(title['seasons'])} | {episodes} | {human_size(size)} |"
        )
    lines += [
        "",
        "## 分季明细",
        "",
        "| 番剧 | 季 | 集数 | 体积 | 最近更新 |",
        "| --- | --- | ---: | ---: | --- |",
    ]
    for title in titles:
        for season in title["seasons"]:
            lines.append(
                "| {title} | {season} | {episodes} | {size} | {updated} |".format(
                    title=cell(title["title"]),
                    season=cell(season["name"]),
                    episodes=season["episodes"],
                    size=human_size(season["size"]),
                    updated=(season["updated"] or "")[:10],
                )
            )
    return "\n".join(lines) + "\n"


def write_library_index(openlist):
    """生成番剧库总览并上传；只读扫描，演练模式下也执行。"""
    library_cfg = cfg.get("library") or {}
    root = (library_cfg.get("root") or (cfg["targets"][0]["mount"] if cfg["targets"] else "")).rstrip("/")
    if not root:
        die("libraryIndex 缺少扫描目录")
    target_path = library_cfg.get("path") or f"{root}/README.md"
    titles = scan_library(openlist, root)
    local = Path(cfg["stateDir"]) / "README.md"
    local.write_text(render_library(titles, root), encoding="utf-8")
    openlist.put(local, target_path)
    log(
        "info",
        "library_index_written",
        path=target_path,
        titles=len(titles),
        seasons=sum(len(title["seasons"]) for title in titles),
    )


# --------------------------------------------------------------------------- 归档流程


def staged_size_for(plan, path):
    """源文件已被搬进暂存区时，用计划里的目标路径取暂存副本大小。"""
    staging = Path(cfg["downloadRoot"]) / "Anime"
    for item in plan or []:
        if Path(item["src"]) != path:
            continue
        with contextlib.suppress(OSError):
            return os.path.getsize(staging / item["rel"])
    return None


def settle_signature(torrent):
    """文件集与大小快照；两次一致才认为写入完成。"""
    parts = []
    plan = None
    for entry in sorted(torrent.get("files", []), key=lambda item: item.get("path", "")):
        path = Path(entry["path"])
        size = None
        with contextlib.suppress(OSError):
            size = os.path.getsize(path)
        if size is None:
            # 上一轮已经搬进暂存区：拿暂存副本参与签名，否则任务会永远卡在 settle 里。
            if plan is None:
                plan, _ = plan_files(torrent)
            size = staged_size_for(plan, path)
            if size is None:
                return None
        parts.append(f"{path.name}:{size}")
    return "|".join(parts) if parts else None


def fallback_plan(torrent):
    """命名失败时改投 _unnamed/，保证队列不被卡住。"""
    release = sanitize(torrent_release(torrent))
    plan = []
    for entry in torrent.get("files", []):
        if entry.get("selected") not in ("true", True):
            continue
        path = Path(entry["path"])
        if path.suffix.lower() not in VIDEO_EXTS | SUB_EXTS:
            continue
        plan.append(
            {
                "src": entry["path"],
                "rel": f"_unnamed/{release}/{sanitize(path.name)}",
                "size": int(entry.get("length") or 0),
                "subtitle": path.suffix.lower() in SUB_EXTS,
                "title": "_unnamed",
                "season": 0,
                "episode": 0,
            }
        )
    return plan or None


def stage(plan):
    """把文件改名搬进暂存目录，返回 [(item, 本地路径)]。"""
    staging = Path(cfg["downloadRoot"]) / "Anime"
    staged = []
    for item in plan:
        source = Path(item["src"])
        destination = staging / item["rel"]
        if destination.exists() and not source.exists():
            # 上一轮已搬进暂存区，本轮直接重试上传
            staged.append((item, destination))
            continue
        if not source.exists():
            log("warning", "stage_source_missing", src=str(source))
            continue
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists() and destination.stat().st_size == source.stat().st_size:
            log("info", "stage_skip_existing", path=str(destination))
        else:
            try:
                shutil.move(str(source), str(destination))
            except OSError as exc:
                log("warning", "stage_move_failed", src=str(source), error=str(exc)[:200])
                continue
        staged.append((item, destination))
    return staged


def upload_one(openlist, local, remote):
    # 0 字节源文件一律视为未下载完成：aria2 会先建占位文件再填数据，
    # 上传它只会把云盘写成空文件，随后本地副本被清掉 → 永久丢集。
    if os.path.getsize(local) <= 0:
        raise RuntimeError(f"源文件为空，拒绝上传：{local}")
    for attempt in range(1, cfg["retryMax"] + 1):
        try:
            existing = openlist.stat(remote)
            if existing is not None:
                # 只按「大小一致」才跳过：云盘上可能有上次中断留下的 0 字节占位文件。
                local_size = os.path.getsize(local)
                if existing.get("size") == local_size:
                    log("info", "upload_skip_existing", remote=remote)
                    return True
                log(
                    "warning",
                    "upload_remote_size_mismatch",
                    remote=remote,
                    remoteSize=existing.get("size"),
                    localSize=local_size,
                )
            openlist.put(local, remote)
            ok, detail = openlist.verify(local, remote, cfg["verifyMode"])
            if ok:
                log("info", "upload_ok", remote=remote, detail=detail)
                return True
            raise RuntimeError(f"校验失败：{detail}")
        except Exception as exc:  # noqa: BLE001 - 网络与云盘错误统一退避重试
            delay = 0 if attempt == cfg["retryMax"] else min(240, 5**attempt)
            log(
                "warning",
                "upload_retry",
                attempt=attempt,
                remote=remote,
                error=str(exc)[:400],
                next_delay=delay,
            )
            if attempt == cfg["retryMax"]:
                return False
            time.sleep(delay)
    return False


def purge_leftovers(torrent):
    """归档成功后删掉该种子目录里没被归档的剩余文件（字体包、封面、.aria2 控制文件）。"""
    if not cfg.get("purgeLeftovers"):
        return
    candidates = []
    for entry in torrent.get("files", []):
        path = Path(entry.get("path", ""))
        if not path.name:
            continue
        candidates.append(path)
        candidates.append(Path(f"{path}.aria2"))
    info_hash = torrent.get("infoHash") or ""
    if info_hash:
        candidates.append(Path(torrent.get("dir", "")) / f"{info_hash}.torrent")
    # 多文件种子的控制文件就放在任务目录旁边：<dir>.aria2
    candidates.append(Path(f"{torrent.get('dir', '')}.aria2"))
    removed = 0
    directories = set()
    for path in candidates:
        if not path.is_file():
            continue
        try:
            size = path.stat().st_size
            path.unlink()
        except OSError as exc:
            log("warning", "purge_leftover_failed", path=str(path), error=str(exc)[:200])
            continue
        removed += size
        directories.add(path.parent)
    for directory in sorted(directories, key=lambda item: len(item.parts), reverse=True):
        while directory.is_dir() and not any(directory.iterdir()):
            with contextlib.suppress(OSError):
                directory.rmdir()
            directory = directory.parent
    if removed:
        log("info", "purge_leftovers", bytes=removed, MiB=round(removed / 1024**2, 1))


def cleanup(staged, torrent):
    """删除已归档的本地文件，并清理空目录。"""
    staging = Path(cfg["downloadRoot"]) / "Anime"
    directories = set()
    for _, destination in staged:
        destination.unlink(missing_ok=True)
        directories.add(destination.parent)
    for directory in sorted(directories, key=lambda path: len(path.parts), reverse=True):
        while directory != staging and directory.is_dir() and not any(directory.iterdir()):
            directory.rmdir()
            directory = directory.parent
    origin = Path(torrent.get("dir", ""))
    if origin.is_dir() and origin != staging and not any(origin.iterdir()):
        with contextlib.suppress(OSError):
            origin.rmdir()


def handle(torrent, state, openlist, aria2):
    gid = torrent["gid"]
    release = torrent_release(torrent)
    entry = state["entries"].get(gid)
    if entry and entry.get("status") == "done":
        return False
    if entry and entry.get("nextAttempt", 0) > time.time():
        return False

    plan, error = plan_files(torrent)
    unnamed = plan is None
    if unnamed:
        plan = fallback_plan(torrent)
        if plan is None:
            log("warning", "plan_failed", gid=gid, release=release, error=error)
            return False

    head = plan[0]
    total_bytes = sum(item["size"] for item in plan)
    record = {
        "release": release,
        "title": head["title"],
        "season": head["season"],
        "episode": head["episode"],
        "bytes": total_bytes,
        "files": len(plan),
        "unnamed": unnamed,
        "reason": error if unnamed else "",
        "where": plan[0]["rel"].rsplit("/", 1)[0] if unnamed else "",
    }

    if cfg["dryRun"]:
        # 演练模式不动磁盘也不动状态，只把将要执行的动作写进日志。
        log(
            "info",
            "dry_run_plan",
            gid=gid,
            release=release,
            unnamed=unnamed,
            files=[item["rel"] for item in plan],
            **{key: record[key] for key in ("title", "season", "episode", "bytes")},
        )
        return False

    entry = state["entries"].setdefault(gid, {})
    entry.update(record)

    staged = stage(plan)
    if not staged:
        log("warning", "stage_empty", gid=gid)
        return False

    targets = cfg["targets"]
    for item, local in staged:
        for target in targets:
            remote = target["mount"].rstrip("/") + "/" + item["rel"]
            if not upload_one(openlist, local, remote):
                entry["status"] = "pending"
                entry["attempts"] = entry.get("attempts", 0) + 1
                entry["nextAttempt"] = int(time.time()) + min(7200, 300 * 2 ** entry["attempts"])
                log("error", "archive_deferred", gid=gid, remote=remote, attempts=entry["attempts"])
                save_state(state)
                return False

    cleanup(staged, torrent)
    purge_leftovers(torrent)
    if not gid.startswith("orphan-"):
        try:
            aria2.remove(gid)
        except Exception as exc:  # noqa: BLE001 - 任务记录清理失败不影响归档结果
            log("warning", "aria2_remove_failed", gid=gid, error=str(exc))

    entry["status"] = "done"
    entry["archivedAt"] = datetime.now(UTC).strftime("%Y-%m-%d %H:%M")
    entry["attempts"] = 0
    entry["nextAttempt"] = 0
    if not unnamed:
        state["budget"][month_key()] = state["budget"].get(month_key(), 0) + total_bytes
    log("info", "archived", gid=gid, title=head["title"], season=head["season"], episode=head["episode"], unnamed=unnamed)
    return True


def hold_reason(state):
    """返回阻止领取新任务的原因；None 表示可以继续。"""
    used = state["budget"].get(month_key(), 0)
    if used >= cfg["monthlyDownloadBudgetGiB"] * GiB:
        return "budget"
    free = disk_free()
    if free < cfg["criticalGiB"] * GiB:
        return "disk-critical"
    if free < cfg["lowWaterGiB"] * GiB:
        return "disk-low"
    return None


def scan_orphans(aria2, state):
    """找出已被 aria2 遗忘但已完成下载的文件，合成等价的种子记录。"""
    if not cfg["orphanScan"]["enable"]:
        return []
    root = Path(cfg["downloadRoot"]) / "downloads"
    if not root.is_dir():
        return []
    known = aria2.all_files()
    cutoff = time.time() - cfg["orphanScan"]["minAgeMinutes"] * 60
    settled = {}
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if str(path) in known:
            continue
        if Path(f"{path}.aria2").exists():
            # 带控制文件说明还在下载，不算孤儿。
            continue
        with contextlib.suppress(OSError):
            info = path.stat()
            if info.st_mtime <= cutoff:
                settled.setdefault(path.parent, []).append(path)

    torrents = []
    for parent, paths in sorted(settled.items()):
        if not any(path.suffix.lower() in VIDEO_EXTS for path in paths):
            continue
        # 多文件种子的控制文件是 <dir>.aria2（放在任务目录旁边），存在即说明还在下载。
        if Path(f"{parent}.aria2").exists():
            continue
        sizes = {}
        for path in paths:
            with contextlib.suppress(OSError):
                sizes[path] = path.stat().st_size
        empty = [path.name for path in paths if sizes.get(path, 0) <= 0]
        video_bytes = sum(
            size for path, size in sizes.items() if path.suffix.lower() in VIDEO_EXTS
        )
        if empty or video_bytes < MIN_VIDEO_BYTES:
            # aria2 记录丢失时，未完成的下载会留下 0 字节占位文件或半截正片。
            log(
                "warning",
                "orphan_incomplete",
                dir=str(parent),
                emptyFiles=len(empty),
                videoMiB=round(video_bytes / 1024 / 1024, 2),
            )
            continue
        files = []
        for path in sorted(paths):
            files.append({"path": str(path), "length": str(sizes[path]), "selected": "true"})
        gid = "orphan-" + hashlib.sha256(str(parent).encode()).hexdigest()[:16]
        torrents.append(
            {
                "gid": gid,
                "status": "complete",
                "dir": str(parent),
                "files": files,
                "bittorrent": {"info": {"name": parent.name}},
            }
        )
        log("info", "orphan_found", gid=gid, dir=str(parent), files=len(files))
    return torrents


def cycle(aria2, openlist, state, stable, processed, last_flush):
    reason = hold_reason(state)
    if reason == "disk-critical":
        log("error", "disk_critical", freeGiB=round(disk_free() / GiB, 2))
        try:
            aria2.pause_all()
        except Exception as exc:  # noqa: BLE001
            log("warning", "aria2_pause_failed", error=str(exc))
    if reason:
        notify(state, reason)

    torrents = aria2.completed()
    pending = 0
    for torrent in torrents:
        gid = torrent["gid"]
        entry = state["entries"].get(gid)
        retrying = bool(entry) and entry.get("status") == "pending"
        if not retrying:
            signature = settle_signature(torrent)
            if signature is None:
                continue
            first_seen = stable.get(gid)
            if first_seen is None or first_seen[1] != signature:
                stable[gid] = (time.time(), signature)
                pending += 1
                continue
            if time.time() - first_seen[0] < cfg["settleSeconds"]:
                pending += 1
                continue
        if reason and not cfg["dryRun"]:
            pending += 1
            continue
        if handle(torrent, state, openlist, aria2):
            processed += 1
            stable.pop(gid, None)

    for torrent in scan_orphans(aria2, state):
        gid = torrent["gid"]
        entry = state["entries"].get(gid)
        if entry and entry.get("status") == "done":
            continue
        if entry and entry.get("nextAttempt", 0) > time.time():
            continue
        if reason and not cfg["dryRun"]:
            pending += 1
            continue
        if handle(torrent, state, openlist, aria2):
            processed += 1

    if processed and (processed % cfg["index"]["flushEvery"] == 0 or time.time() - last_flush > cfg["index"]["flushDailyHours"] * 3600):
        try:
            flush_index(state, openlist)
            last_flush = time.time()
        except Exception as exc:  # noqa: BLE001 - 索引失败不影响归档
            log("warning", "index_flush_failed", error=str(exc))

    state["settle"] = {gid: [seen, signature] for gid, (seen, signature) in stable.items()}
    save_state(state)
    write_status(state, reason, pending)
    return processed, last_flush


def main():
    import argparse

    parser = argparse.ArgumentParser(prog="anime-archiver", description="追番归档器")
    parser.add_argument("--once", action="store_true", help="只跑一轮后退出")
    parser.add_argument("--interval", type=int, default=60, help="轮询间隔（秒）")
    parser.add_argument("--dry-run", action="store_true", help="强制演练模式")
    parser.add_argument("--library", action="store_true", help="只生成番剧库总览后退出")
    args = parser.parse_args()

    config_path = os.environ.get("ANIME_ARCHIVE_CONFIG", "")
    if not config_path:
        die("缺少环境变量 ANIME_ARCHIVE_CONFIG")
    global cfg
    try:
        cfg = json.loads(Path(config_path).read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        die(f"无法读取配置文件 {config_path}：{exc}")
    if args.dry_run:
        cfg["dryRun"] = True

    Path(cfg["stateDir"]).mkdir(parents=True, exist_ok=True)
    openlist = OpenList(cfg["openlist"]["url"], read_secret(cfg["openlist"]["tokenFile"]))

    if args.library:
        write_library_index(openlist)
        return

    aria2 = Aria2(cfg["aria2"]["rpcUrl"], read_secret(cfg["aria2"]["secretFile"]))

    lock_file = Path(cfg["stateDir"]) / "lock"
    with lock_file.open("w", encoding="utf-8") as lock_handle:
        try:
            fcntl.flock(lock_handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            log("warning", "already_running")
            return
        run(args, aria2, openlist)


def run(args, aria2, openlist):
    state = load_state()
    # 稳定窗口的首次采样时间需要跨进程保留，否则每次重启都要重新计时。
    stable = {gid: (seen, signature) for gid, (seen, signature) in state.get("settle", {}).items()}
    processed = 0
    last_flush = time.time()

    log(
        "info",
        "archiver_start",
        dryRun=cfg["dryRun"],
        targets=[target["name"] for target in cfg["targets"]],
    )
    while True:
        try:
            processed, last_flush = cycle(aria2, openlist, state, stable, processed, last_flush)
        except Exception as exc:  # noqa: BLE001 - 单轮失败不退出，等待下一轮
            log("error", "cycle_failed", error=str(exc)[:400])
        if args.once:
            break
        time.sleep(args.interval)


if __name__ == "__main__":
    main()

