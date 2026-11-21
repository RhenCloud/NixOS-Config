#!/usr/bin/env python3
"""归档器纯函数回归测试（离线、无副作用）。

覆盖：种子名解析、语言后缀、非法字符清洗、命名模板渲染、
文件计划生成、命名失败兜底、索引与失败清单渲染。
"""

import importlib.util
import os
import sys
import tempfile
import time
from pathlib import Path
from typing import Any, cast

ARCHIVER = sys.argv[1]

spec = importlib.util.spec_from_file_location("archiver", ARCHIVER)
if spec is None or spec.loader is None:
    print(f"无法加载归档器模块：{ARCHIVER}")
    sys.exit(1)
archiver = cast(Any, importlib.util.module_from_spec(spec))
spec.loader.exec_module(archiver)

# 这些用例不落盘，路径只用于构造配置。
archiver.cfg = {
    "stateDir": "test-state",
    "downloadRoot": "test-anime",
    "naming": {
        "template": "{title} S{season:02}E{episode:02}{ext}",
        "seasonDir": "Season {season:02}",
        "includeYear": False,
        "subtitleSuffix": True,
        "keepGroupTag": False,
        "abMetadata": False,
    },
}

failures = []


def check(label, actual, expected):
    if actual != expected:
        failures.append(f"{label}：期望 {expected!r}，实际 {actual!r}")


# --- 种子名解析 -------------------------------------------------------------
CASES = [
    ("[Nekomoe kissaten][Sousou no Frieren][07][1080p][CHS].mkv", "Sousou no Frieren", None, 7),
    ("[ANi] 杜鹃的婚约 - 07 [1080P][CHS].mkv", "杜鹃的婚约", None, 7),
    ("葬送的芙莉莲 - 第07话.mkv", "葬送的芙莉莲", None, 7),
    ("Frieren S01E07.mkv", "Frieren", 1, 7),
    ("Some Anime - 12.mkv", "Some Anime", None, 12),
    # 全角【】与「★10月新番★」噪声
    ("【幻樱字幕组】【10月新番】【葬送的芙莉莲 Sousou no Frieren】【01】【GB_MP4】【1080P】", "葬送的芙莉莲 Sousou no Frieren", None, 1),
    ("【喵萌奶茶屋】★10月新番★[葬送的芙莉莲][01][1080p][简日双语]", "葬送的芙莉莲", None, 1),
    # 季号：中文「第二季」、S02、Season 2
    ("[Airota&LoliHouse] 无职转生 第二季 / Mushoku Tensei S2 - 02 [WebRip 1080p]", "无职转生 第二季", 2, 2),
    ("[Group] Mushoku Tensei S02E05 [1080p]", "Mushoku Tensei", 2, 5),
]

for name, title, season, episode in CASES:
    check(f"parse_release({name})", archiver.parse_release(name), (title, season, episode))

# --- 语言后缀 ---------------------------------------------------------------
check("lang_suffix(.chs)", archiver.lang_suffix("Show S01E07.chs.ass"), ".chs")
check("lang_suffix(plain)", archiver.lang_suffix("Show S01E07.ass"), "")

# --- 非法字符清洗 -----------------------------------------------------------
check("sanitize", archiver.sanitize('a/b\\c:d*e?f"g<h>i|j'), "a b c d e f g h i j")
check("sanitize(空)", archiver.sanitize("  . "), "unnamed")

# --- 命名模板渲染 -----------------------------------------------------------
check(
    "build_name(video)",
    archiver.build_name("杜鹃的婚约", 1, 7, "/d/杜鹃的婚约 - 07.chs.mkv"),
    "杜鹃的婚约 S01E07.mkv",
)
check(
    "build_name(sub)",
    archiver.build_name("杜鹃的婚约", 1, 7, "/d/杜鹃的婚约 - 07.chs.ass", subtitle=True),
    "杜鹃的婚约 S01E07.chs.ass",
)

# --- 文件计划 ---------------------------------------------------------------
episode_torrent = {
    "gid": "g2",
    "dir": "/downloads/dl",
    "bittorrent": {"info": {"name": "[ANi] 杜鹃的婚约 - 07 [1080P][CHS]"}},
    "files": [
        {
            "path": "/downloads/dl/[ANi] 杜鹃的婚约 - 07 [1080P][CHS].mkv",
            "selected": "true",
            "length": "1000",
        },
        {
            "path": "/downloads/dl/[ANi] 杜鹃的婚约 - 07 [1080P][CHS].chs.ass",
            "selected": "true",
            "length": "10",
        },
        {"path": "/downloads/dl/readme.txt", "selected": "true", "length": "1"},
    ],
}
plan, error = archiver.plan_files(episode_torrent)
check("plan_files 错误", error, None)
check(
    "plan_files 相对路径",
    [item["rel"] for item in (plan or [])],
    [
        "杜鹃的婚约/Season 01/杜鹃的婚约 S01E07.mkv",
        "杜鹃的婚约/Season 01/Extra/杜鹃的婚约 S01E07.chs.ass",
        "杜鹃的婚约/Season 01/Extra/杜鹃的婚约 readme.txt",
    ],
)
check("plan_files 字幕标记", [item["subtitle"] for item in (plan or [])], [False, True, False])
check("plan_files 视频在前", [item["video"] for item in (plan or [])], [True, False, False])

# 字体包等附件也进 Extra/，命名时去掉分组标记与番名重复
font_torrent = {
    "gid": "g3",
    "dir": "/downloads/Season 1",
    "bittorrent": {
        "info": {"name": "[BeanSub&FZSD&LoliHouse] Jujutsu Kaisen - 59 [WebRip 1080p HEVC-10bit AAC ASSx2]"}
    },
    "files": [
        {
            "path": "/downloads/Season 1/[BeanSub&FZSD&LoliHouse] Jujutsu Kaisen - 59 [WebRip 1080p HEVC-10bit AAC ASSx2]/[BeanSub&FZSD&LoliHouse] Jujutsu Kaisen - 59 [WebRip 1080p HEVC-10bit AAC ASSx2].mkv",
            "selected": "true",
            "length": "100",
        },
        {
            "path": "/downloads/Season 1/[BeanSub&FZSD&LoliHouse] Jujutsu Kaisen - 59 [WebRip 1080p HEVC-10bit AAC ASSx2]/[BeanSub&FZSD&LoliHouse] Jujutsu Kaisen - Fonts.7z",
            "selected": "true",
            "length": "50",
        },
        {
            "path": "/downloads/Season 1/[BeanSub&FZSD&LoliHouse] Jujutsu Kaisen - 59 [WebRip 1080p HEVC-10bit AAC ASSx2]/Jujutsu Kaisen - 59.cht.ass",
            "selected": "true",
            "length": "10",
        },
    ],
}
font_plan, font_error = archiver.plan_files(font_torrent)
check("plan_files(字体包) 错误", font_error, None)
check(
    "plan_files(字体包) 相对路径",
    [item["rel"] for item in (font_plan or [])],
    [
        "Jujutsu Kaisen/Season 01/Jujutsu Kaisen S01E59.mkv",
        "Jujutsu Kaisen/Season 01/Extra/Jujutsu Kaisen S01E59.cht.ass",
        "Jujutsu Kaisen/Season 01/Extra/Jujutsu Kaisen Fonts.7z",
    ],
)
check("plan_files(字体包) 体积合计", sum(item["size"] for item in (font_plan or [])), 160)

# --- 命名失败兜底 -----------------------------------------------------------
pack_torrent = {
    "gid": "g1",
    "dir": "/downloads/Pack",
    "bittorrent": {"info": {"name": "Random Pack"}},
    "files": [
        {"path": "/downloads/Pack/Random Pack.mkv", "selected": "true", "length": "100"},
        {"path": "/downloads/Pack/Random Pack.ass", "selected": "true", "length": "10"},
    ],
}
named, naming_error = archiver.plan_files(pack_torrent)
check("plan_files(无法确定集数)", named, None)
if not naming_error:
    failures.append("plan_files 未对无法确定集数的种子报错")

fallback = archiver.fallback_plan(pack_torrent) or []
check("fallback_plan 数量", len(fallback), 2)
check(
    "fallback_plan 相对路径",
    sorted(item["rel"] for item in fallback),
    ["_unnamed/Random Pack/Random Pack.ass", "_unnamed/Random Pack/Random Pack.mkv"],
)

# --- 派生视图 ---------------------------------------------------------------
state = {
    "entries": {
        "g2": {
            "release": "[ANi] 杜鹃的婚约 - 07 [1080P][CHS]",
            "title": "杜鹃的婚约",
            "season": 1,
            "episode": 7,
            "bytes": 2 * 1024**3,
            "status": "done",
            "archivedAt": "2026-11-21 14:03",
            "unnamed": False,
        },
        "g1": {
            "release": "Random Pack",
            "unnamed": True,
            "reason": "无法确定集数",
            "where": "_unnamed/Random Pack",
            "archivedAt": "2026-11-21 14:10",
        },
    }
}

index = archiver.render_index(state)
check("index 表头", index.splitlines()[0], "| 番剧 | 季 | 集 | 大小 | 归档时间 | 原始种子名 |")
check("index 行数", len(index.splitlines()), 3)
check(
    "index 数据行",
    index.splitlines()[2],
    "| 杜鹃的婚约 | 01 | 07 | 2.00 GiB | 2026-11-21 14:03 | [ANi] 杜鹃的婚约 - 07 [1080P][CHS] |",
)

unnamed = archiver.render_unnamed(state)
check(
    "unnamed 表头",
    unnamed.splitlines()[0],
    "| 归档时间 | 原始种子名 | 失败原因 | 云盘落点 |",
)
check(
    "unnamed 数据行",
    unnamed.splitlines()[2],
    "| 2026-11-21 14:10 | Random Pack | 无法确定集数 | _unnamed/Random Pack |",
)

# --- 番剧库总览 -------------------------------------------------------------
check("集数解析", archiver.episode_of("Jujutsu Kaisen S01E07.mkv"), 7)
check("季号解析", archiver.season_number_of("Season 02"), 2)
check("无季号目录", archiver.season_number_of("未分季"), None)


class FakeOpenList:
    """最小目录树：用来验证扫描逻辑不依赖真实云盘。"""

    def __init__(self, tree):
        self.tree = tree

    def list_dir(self, path):
        return self.tree.get(path)


fake_tree = {
    "/Anime": [
        {"name": "Jujutsu Kaisen", "is_dir": True},
        {"name": "Sousou no Frieren", "is_dir": True},
        {"name": "README.md", "is_dir": False, "size": 0},
        {"name": "_archive-index.md", "is_dir": False, "size": 0},
    ],
    "/Anime/Jujutsu Kaisen": [
        {"name": "Season 01", "is_dir": True},
        {"name": "Season 02", "is_dir": True},
    ],
    "/Anime/Jujutsu Kaisen/Season 01": [
        {"name": "Jujutsu Kaisen S01E01.mkv", "is_dir": False, "size": 1024**3},
        {"name": "Jujutsu Kaisen S01E02.mkv", "is_dir": False, "size": 1024**3},
        {"name": "Jujutsu Kaisen S01E02.chs.ass", "is_dir": False, "size": 1024},
    ],
    "/Anime/Jujutsu Kaisen/Season 02": [
        {"name": "Jujutsu Kaisen S02E01.mkv", "is_dir": False, "size": 1024**3},
    ],
    "/Anime/Sousou no Frieren": [
        {"name": "Sousou no Frieren S01E01.mkv", "is_dir": False, "size": 1024**2},
    ],
}

titles = archiver.scan_library(FakeOpenList(fake_tree), "/Anime")
check("扫描跳过 md 与下划线目录", [item["title"] for item in titles], ["Jujutsu Kaisen", "Sousou no Frieren"])
check("季数统计", [len(item["seasons"]) for item in titles], [2, 1])
check("分季集数", [season["episodes"] for season in titles[0]["seasons"]], [2, 1])
check("未分季回落", titles[1]["seasons"][0]["name"], "未分季")

library = archiver.render_library(titles, "/Anime")
check("总览标题", library.splitlines()[0], "# 番剧库总览")
check("总览表头", library.splitlines()[6], "| 番剧 | 季数 | 集数 | 体积 |")
check("总览数据行", library.splitlines()[8], "| Jujutsu Kaisen | 2 | 3 | 3.00 GiB |")
check("总览含分季明细", "## 分季明细" in library, True)

# --- 孤儿扫描 ---------------------------------------------------------------


class FakeAria2:
    """只提供 all_files()：模拟 aria2 记录里的文件集合。"""

    def __init__(self, known):
        self.known = known

    def all_files(self):
        return self.known


sandbox = Path(tempfile.mkdtemp())
season_dir = sandbox / "downloads" / "Bangumi" / "某番" / "Season 1"
season_dir.mkdir(parents=True)
orphan_video = season_dir / "Some Anime - 07 [1080p].mkv"
# 正片必须够大，否则会被当成未下载完成的占位文件（MIN_VIDEO_BYTES = 1 MiB）。
with open(orphan_video, "wb") as handle:
    handle.truncate(2 * 1024 * 1024)
orphan_font = season_dir / "Some Anime - Fonts.7z"
orphan_font.write_bytes(b"y" * 16)
busy_video = season_dir / "Some Anime - 08 [1080p].mkv"
busy_video.write_bytes(b"z" * 16)
Path(f"{busy_video}.aria2").write_text("", encoding="utf-8")
# 多文件种子的控制文件在任务目录旁边：存在即说明还在下载。
blocked_dir = season_dir / "Some Anime - 09 [1080p]"
blocked_dir.mkdir()
with open(blocked_dir / "Some Anime - 09 [1080p].mkv", "wb") as handle:
    handle.truncate(2 * 1024 * 1024)
Path(f"{blocked_dir}.aria2").write_text("", encoding="utf-8")
# 未完成的下载：aria2 已建占位文件但没填数据。
partial_dir = season_dir / "Some Anime - 10 [1080p]"
partial_dir.mkdir()
(partial_dir / "Some Anime - 10 [1080p].mkv").write_bytes(b"")
stale = time.time() - 7200
for path in (
    orphan_video,
    orphan_font,
    blocked_dir / "Some Anime - 09 [1080p].mkv",
    partial_dir / "Some Anime - 10 [1080p].mkv",
):
    os.utime(path, (stale, stale))

archiver.cfg = {
    **archiver.cfg,
    "downloadRoot": str(sandbox),
    "orphanScan": {"enable": True, "minAgeMinutes": 60},
}

orphans = archiver.scan_orphans(FakeAria2(set()), {})
check("孤儿目录分组数", len(orphans), 1)
check("孤儿 gid 前缀", orphans[0]["gid"].startswith("orphan-"), True)
check("孤儿目录", orphans[0]["dir"], str(season_dir))
names = sorted(Path(entry["path"]).name for entry in orphans[0]["files"])
check("孤儿只收已稳定文件", names, ["Some Anime - 07 [1080p].mkv", "Some Anime - Fonts.7z"])
check("下载中的文件不算孤儿", busy_video.name in names, False)
check("带 <dir>.aria2 的目录不算孤儿", any(entry["dir"] == str(blocked_dir) for entry in orphans), False)
check("0 字节正片不算孤儿", any(entry["dir"] == str(partial_dir) for entry in orphans), False)
check(
    "aria2 已知文件不算孤儿", archiver.scan_orphans(FakeAria2({str(orphan_video), str(orphan_font)}), {}), []
)
archiver.cfg["orphanScan"]["enable"] = False
check("关闭后不扫描", archiver.scan_orphans(FakeAria2(set()), {}), [])

# --- 结果 -------------------------------------------------------------------
if failures:
    print("归档器回归测试失败：")
    for item in failures:
        print(f"  - {item}")
    sys.exit(1)

print("归档器回归测试通过")
