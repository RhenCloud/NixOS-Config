# 追番下载与云盘自动归档 设计方案

> 状态：设计稿，未落地。落地前需通过第 11 节的验证项。
> 本条基线已按实测参数确定：流量 600 GB/月、根分区 14 GiB 可用、OneDrive 家庭版 1 TB、暂只挂 OneDrive、下载器用 **aria2**、需要云盘归档索引。

## 1. 目标与非目标

目标：

- 订阅（Mikan 等聚合 RSS）→ 自动下载 → 自动整理命名 → 上传云盘 → 立即删除本地，全链路无人值守。
- `hd-sg-1`（Hostinger，新加坡）只承担**控制面**：RSS 解析、番剧元数据、下发下载、通知，**不落盘、不接触视频文件**。
- `yc-hk-1`（香港，30 GiB 盘）承担**数据面**：aria2 下载、归档器（命名+上传+校验+删除）、OpenList（已部署）。

非目标（本次不做）：

- 本地媒体库与长期保种（`seeding = none`）。
- Google Drive（用户指示暂缓）—— 但归档器的 `targets` 是列表，日后增加一项即可，流量模型同步变化（见第 8 节）。
- 云盘之间的服务端复制（OneDrive→GDrive 无法服务端直传，只能过本机）。

## 2. 拓扑

```text
                    ┌────────────────────────────────────────────┐
  Mikan RSS ──────▶ │ hd-sg-1  (Hostinger SG, 控制面，零落盘)      │
  TMDB              │  ┌──────────────────────────────────────┐  │
                    │  │ AutoBangumi 4.x  (docker compose)    │  │
                    │  │  RSS 解析 / 番剧库 / 季集元数据        │  │
                    │  │  rename ✗ hardlink ✗ refresh ✗        │  │
                    │  │  WebUI :7892（仅隧道/管理 IP 可达）    │  │
                    │  └───────────┬──────────────────────────┘  │
                    └──────────────┼─────────────────────────────┘
                       ① 隧道内 JSON-RPC（addUri）
                                   │  SSH 本地端口转发
                                   │  127.0.0.1:16800 → HK 127.0.0.1:6800
                                   │
                    ┌──────────────▼─────────────────────────────┐
                    │ yc-hk-1  (香港, 30 GiB, 数据面)              │
                    │  ┌──────────────────────────────────────┐  │
                    │  │ aria2 (native, RPC 仅 127.0.0.1)      │  │
                    │  │  /var/lib/anime/downloads            │  │
                    │  │    ← btrfs 子卷 + qgroup 8 GiB 硬限   │  │
                    │  │  seed-time=0（完成即成 complete）      │  │
                    │  └───────────┬──────────────────────────┘  │
                    │  ┌───────────▼──────────────────────────┐  │
                    │  │ anime-archiver (native, Python)      │  │
                    │  │  ② mv 命名 → ③ 上传 → ④ 校验 → ⑤ 删   │  │
                    │  │  ⑥ 写 state.json + _archive-index.md │  │
                    │  └───────────┬──────────────────────────┘  │
                    │  ┌───────────▼──────────────────────────┐  │
                    │  │ OpenList  (127.0.0.1:5244)           │  │
                    │  │  /Private/OneDrive ← 家庭版 1 TB     │  │
                    │  └──────────────────────────────────────┘  │
                    └────────────────────────────────────────────┘
                              ⑦ PUT /api/fs/put
                                    ↓
                     OneDrive  /Anime/<番剧>/Season NN/…
```

跨主机只有一条连接：**SG → HK 的 SSH 端口转发**（aria2 JSON-RPC）。HK 侧 aria2 的 `rpc-listen-all=false` 保持不变，公网无端口暴露。

> 现状补充：`hd-sg-1` 实际跑的是 **Ubuntu**，AutoBangumi 由用户在宿主机上用 docker compose 手工部署，不经过本仓库的 NixOS 模块。因此 `${config.virtualisation.oci-containers}` 相关的 `modules/server/autobangumi` 在本轮落地中**保持默认关闭**，仅作为「hd-sg-1 将来若重装 NixOS」的备用路径；隧道单元相应改为 Ubuntu 侧的 systemd 单元（见 §10.4）。

## 3. 职责矩阵

| 组件 | 主机 | 形态 | 职责 | 状态 |
| --- | --- | --- | --- | --- |
| AutoBangumi 4.x | hd-sg-1 | OCI (podman) | RSS 解析、番剧/季集元数据、下发种子、通知 | 新建 |
| aria2 | yc-hk-1 | native（**模块已存在** `modules/server/aria2`） | 下载、`seed-time=0` 完成即停 | 扩展现有模块 |
| anime-archiver | yc-hk-1 | native（Python + systemd） | 命名、上传、校验、删除、记账、索引 | 新建 |
| OpenList | yc-hk-1 | OCI（已部署） | OneDrive 挂载与上传 API | 已部署 |
| Caddy | yc-hk-1 | native（已部署） | `olist.rhen.cloud` | 已部署 |
| mailer | yc-hk-1 | OCI（已部署） | 归档失败/HOLD 告警 | 已部署 |
| Beszel Agent | 两台 | OCI | 磁盘水位、内存 | HK 已开，SG 需开启 |

## 4. 参数基线（已确认项与推导）

| 项 | 实测/确认值 | 直接推论 |
| --- | --- | --- |
| HK 月流量 | 600 GB | 单目标流量 ≈ `2D`；业务上限取 **`D = 200 GiB/月`** → 实际流量约 400 GB，占配额 67%，留 200 GB 缓冲 |
| 下载预算 | **200 GiB/月**（用户指定） | 归档器内置预算器，耗尽即 HOLD 至次月 |
| 根分区 | 30 GiB，已用 16 GiB，可用 **14 GiB** | 归档区 qgroup **8 GiB**，系统留 6 GiB；并发下载降到 1 |
| 内存 | **1.92 GiB 总计，可用 875 MiB，swap 已用 542 MiB** | 新增常驻必须压到 **≤ 110 MiB**；归档器纯标准库 + curl 传文件；aria2 缓存降到 16 MiB（见 7.1） |
| OneDrive | 家庭版 1 TB（单文件 250 GB） | 按 200 GiB/月灌满约 **5 个月**（时间只取决于总体积，与单集大小无关）；不够时后续扩容 |
| 订阅质量 | **不做限制** | 不锁分辨率/编码组；单集体积只影响「每月能追多少集」，不影响灌满时间 |
| 云盘目标 | 暂只 OneDrive | `targets = [onedrive]`；GDrive 预留为列表项 |
| 命名 | **不保留字幕组标记** | 模板只输出 `<Title> SNNENN.ext`，目录名不含 `[Lilith-Raws]` 之类前缀 |
| 归档索引 | 需要，且 `_unnamed.md` **单独成文件** | `_archive-index.md` + `_unnamed.md` 两个派生视图（D10） |
| 下载器 | aria2 | 命名权移交归档器（D2） |

## 5. 关键设计决策

### D1 下载器用 aria2，放弃 qBittorrent

| 维度 | aria2 | qBittorrent-nox |
| --- | --- | --- |
| 常驻内存 | ~30–60 MiB | ~300–500 MiB |
| `seeding = none` | `seed-time=0`，语义直白 | 全局限额 `ratio=0`，有语义陷阱 |
| 重命名 API | **无** | `torrents/renameFile` |
| 本仓库现状 | **模块已存在**（`follow-torrent`/`bt-save-metadata`/`rpc-listen-all=false` 均已配好） | 无 |
| 崩溃恢复 | `force-save` + session 文件 | 自带 |

结论：**aria2 为默认**。代价是 AB 的 `rename` 插件失效，命名改由归档器做（D2）。这个代价其实划算：文件本来就在 HK 本地，归档器直接 `mv` 即可，不依赖任何下载器 API，也顺带**消除了"AB 需要看到远端文件"这一整类风险**。

qBittorrent 保留为可选后端（`rhen.services.animeArchive.downloader = "aria2" | "qbittorrent"`），仅当日后需要 API 级重命名/更细的队列管理时才切换。

### D2 命名由归档器负责（aria2 模式下）

```text
aria2 落地（扁平）                   归档器整理（目标结构）
downloads/[Lilith-Raws] Kakkou       downloads/Anime/
  no Iinazuke - 07 [...]/              └── 杜鹃的婚约/
    xxx.mp4                              └── Season 01/
    xxx.chs.ass                                ├── 杜鹃的婚约 S01E07.mp4
                                               └── 杜鹃的婚约 S01E07.chs.ass
```

命名来源**优先用 AB 的元数据**，不自己解析标题：

1. 调 AB REST（`/api/v1/bangumi/` 或事件流）取 `official_title` / `season` / `episode`；
2. 用 AB 的 `info_hash` 或种子名做关联键（AB 添加种子时已知）；
3. 匹配失败才退回正则解析发布名（覆盖常见字幕组前缀/`- 07`/`S01E07`/`第7话`）。

模板固定：`<Title> S<season:02>E<episode:02><ext>`，字幕文件保留语言后缀（`.chs`/`.cht`/`.sc`/`.tc`）并按照主视频同名的 `Title SxxExx.chs.ass` 命名。模板集中在一个选项里，落地后可按季中实际效果调整。

**非视频文件单独放子目录**：字幕、字体包（`Fonts.7z`）、封面等一律放进 `<Title>/Season NN/<extraDir>/`（`extraDir` 默认 `Extra`），正片目录只留视频文件。附件命名 = 番名 + 去掉分组/画质标签的原始名（`[BeanSub&FZSD&LoliHouse] Jujutsu Kaisen - Fonts.7z` → `Jujutsu Kaisen Fonts.7z`），同名时追加 ` (2)`。代价：播放器不会再自动加载同目录字幕，需要手动指定 `Extra/` 下的文件。

正则兜底的已知边界（2026-11-21 实测）：

- 全角 `【】` 先归一化成 `[]`，否则幻樱/诸神那种「全方括号」命名一个字段都抽不出来。
- 整个名字都被括号包住时，取**最长的非标签段**作标题；`10月新番`/`★…★`/`完结` 这类季节性噪声不当作标题。
- 季号支持 `S02`、`Season 2`、`第二季`（中文数字到十二）；抽不到时统一落到 `Season 01`，需要 AB 元数据或手工兜底。
- 无 `bittorrent` 段的普通 HTTP 任务拿不到种子名，会退回「按目录名当发布名」，基本必定落进 `_unnamed`。这是预期行为。

**不保留字幕组标记**（`[Lilith-Raws]` 之类的方括号前缀）：目录与文件名都不带，媒体库识别率更高。代价是丢失溯源信息 —— 用 `_archive-index.md` 的「原始种子名」列补偿，云盘侧仍能查到出自哪个组。

> 为什么不自己从零解析：AB 4.0 内置 Mikan/TMDB 元数据解析与可选 LLM 标题解析，质量远高于自写正则。归档器只做"消费 AB 结果 + 兜底"。

### D3 `seeding = none`

- aria2 `seed-time=0`（现有模块已设置）→ BT 下载完成后立即进入 `complete`，不做种。
- `seed-ratio=0` 同步设置，避免 `seed-time` 被其它条件覆盖。
- 归档器额外保证：处理完成后调用 `aria2.removeDownloadResult(gid)`，把任务记录清出结果列表，不留残余。
- 不需要（也用不上）`hardlink`/`media-server-refresh`，AB 侧一并禁用。

### D4 `local cleanup = immediate`，但受 14 GiB 的硬约束

删除条件：**上传 + 校验通过后立即删**（`os.remove` / `shutil.rmtree` 本地文件 → `removeDownloadResult`）。删除顺序是先文件后记录，避免"记录没了文件还在"。

小盘适配（这是与"标准 1 TB 盘方案"的最大差异）：

- 归档区 `qgroup limit 8 GiB`（子卷 `/var/lib/anime`），**不是** 25 GiB。
- aria2 `max-concurrent-downloads = 1`，`max-concurrent-downloads` 之外的队列由 aria2 自身排队。峰值本地占用 ≈ 当前集 1.4 GiB + 队列中已开写的一集 1.4 GiB ≈ 3 GiB，8 GiB 有 2.6 倍余量。
- 水位闸门：`free < lowWaterGiB (4)` → 不领取新任务（archiver 暂停 `addUri` 之外的推进）；`free < criticalGiB (2.5)` → 暂停 aria2 全部任务 + 邮件。注意这里读的是**整盘 free**，不是子卷 qgroup。
- 额外清理：`journald` 目前**没有**设置 `SystemMaxUse`，30 GiB 盘上必须加（200 MB）；`fast-nix-gc` 已 weekly/7d，HK 建议收紧到 `3d`。

### D5 跨机链路：Caddy 反代（AriaNg 与 AB 共用同一后端）

aria2 只监听 `127.0.0.1:6800`（`rpc-listen-all=false`），公网一个端口都不开。HK 上已有的 Caddy 加两个 vhost：

| vhost | 入口 | 访问控制 | 用途 |
| --- | --- | --- | --- |
| `:8098`（`bind 127.0.0.1`） | Cloudflare Tunnel → `http://127.0.0.1:8098` | Cloudflare Access | AriaNg 页面 + 同源 `/jsonrpc` 反代 |
| `aria-rpc.rhen.cloud`（公网 443） | 灰云 A 记录直连源站 | `@sg remote_ip 81.31.208.183`，其余 `abort` | AB 专用 RPC 入口 |

```caddyfile
:8098 {
  bind 127.0.0.1
  handle /jsonrpc { reverse_proxy 127.0.0.1:6800 }
  handle { root * ${pkgs.ariang}/share/ariang
           file_server }
}

aria-rpc.rhen.cloud {
  tls { dns cloudflare {$CLOUDFLARE_API_TOKEN} }
  @sg remote_ip 81.31.208.183
  handle @sg { reverse_proxy 127.0.0.1:6800 }
  handle { abort }
}
```

AriaNg 侧刻意**不**在源站 443 上给 `aria.rhen.cloud` 建站点：一旦有人拿 IP 直连 443 并带上 Host 头，就能绕过 Cloudflare Access。走 Tunnel + 回环监听就不存在这个口子。Tunnel 里填的 Service 必须是明文 HTTP（`https://127.0.0.1:443` 会因 SNI `127.0.0.1` 与证书域名不符而握手失败）。

为什么这样比“直接开公网 6800”好：

- AriaNg 与 RPC **同源**，不需要 `rpc-allow-origin-all=true`（跨源才要）；
- 两边都走受信任 TLS，AB 的 httpx 严格校验能过（自签证书过不了，AB 没有关校验的开关）；
- 访问控制分层：页面靠 Cloudflare Access（人），RPC 靠 `remote_ip` 限制到 SG（机器）+ aria2 token；
- 零新增组件 —— Caddy 本来就在跑，`ariang` 在 nixpkgs 里也有现成包。

为什么 AB 不走 `aria.rhen.cloud`：CF Access 会在边缘拦下它，而 AB 的 aria2 客户端只会发 JSON-RPC，无法携带 `CF-Access-Client-Id/Secret` 服务令牌。所以 AB 用灰云的 `aria-rpc.rhen.cloud`。

`rhen.services.aria2.rpcListenAll` / `rpcAllowedSources` 选项保留（默认关闭），用 nftables 做源地址白名单，留给“不走 Caddy”的场景。

### D6 上传通道：OpenList API

`PUT /api/fs/put`（流式，`Content-Length` 必填，`File-Path` 为 URL 编码的完整目标路径，`Authorization: <token>`）。流式上传内存占用极小，适合 14 GiB 盘的小机器。

- 校验：`POST /api/fs/get`（或 `list`）比对 **size 相等**。视频 MKV/MP4 传输不会被改写，size 校验足够；`verifyMode = "hash"` 保留但代价是 2 倍下行，不推荐。
- 幂等：上传前先 `list` 目标目录，已存在且 size 一致 → 直接标记该文件完成（重试不会产生重复）。
- 预留 `uploadBackend = "openlist" | "rclone"`：若实测单文件吞吐不达标，切 rclone（`--drive-chunk-size` 类参数只对 GDrive 有意义，OneDrive 收益有限）。
- OneDrive 个人版/家庭版对**大文件走分片上传会话**，OpenList 内部已处理；超过 250 GB 的单文件不可能出现（单集上限约 2 GiB），无需特殊处理。

### D7 归档器在 HK，不在 SG

与文件同机：省去跨洋传输、省 SG 磁盘、读文件走本地页缓存、命名可以 `mv`。代价是不能复用 AB 插件机制 —— 但 AB 插件本来就看不到跨机文件，不算损失。

### D8 AB 配置为「Nix 播种 + 程序自管」混合模式

AB 运行时会改写 `config/config.json`（API key、passkey、插件实例），并自带更新器（自我重启）。因此：

- `/var/lib/autobangumi/{config,data}` bind mount 持久化；
- 首次的下载器地址/RPC secret 由 sops 模板渲染成 `config.json` 种子，其后由 AB 自管理（**不是纯声明式**，需纳入备份）；
- 容器 `restart = unless-stopped`（程序内更新的前提）。

### D9 单目标 → 多目标的结构预留

当前 `targets = [{ name = "onedrive"; mount = "/onedrive/Anime"; }]`。加入 GDrive 只需追加一项，但同时必须把 `monthlyDownloadBudgetGiB` 从 200 降到 130（双写使流量变 `3D`），否则 600 GB 会超。这个耦合写进模块 `assertions`，避免日后忘记。

### D10 云盘派生视图：`_archive-index.md` 与 `_unnamed.md`

两个**独立文件**，都在 `<mount>/Anime/` 下，都由 `state.json` 派生、整文件覆盖上传。

`<mount>/Anime/_archive-index.md`，内容为按番剧分组、按集排序的表格：

```markdown
| 番剧 | 季 | 集 | 大小 | 归档时间 | 原始种子名 |
| --- | --- | --- | --- | --- | --- |
| 杜鹃的婚约 | 01 | 07 | 0.82 GiB | 2026-11-21 14:03 | [Lilith-Raws] Kakkou no Iinazuke - 07 [Baha][WEB-DL][1080p][HEVC][CHT].mkv |
```

- 事实来源仍是本地 `state.json`；索引是**派生视图**，每次归档后重算并从 state 生成。
- 上传方式：整文件覆盖 `PUT`（1000 集约 60 KB，代价可忽略），避免 OpenList 缺少 append API 的问题。
- 频率：每归档 10 集或每日一次（`indexFlushEvery = 10` / `indexFlushDailyHours = 24`），减少小文件覆盖次数。

`_unnamed.md` —— 命名失败/元数据缺失清单，**独立成文**，便于集中人工补救：

| 归档时间 | 原始种子名 | 失败原因 | 云盘落点（现已存的原始名） |
| --- | --- | --- | --- |
| 2026-11-21 15:40 | [XXX] 某番 - 03 [...] | AB 元数据缺失 + 正则无匹配 | /Anime/_unnamed/[XXX] 某番 - 03/ |

约定：

- 命名失败**不阻塞队列**：文件以原种子名落到 `/Anime/_unnamed/`，记一行，继续处理下一集。
- 与 `_archive-index.md` 分开维护，互不干扰；命名补救完成后从 `_unnamed.md` 移入主索引。

### D11 番剧库总览：`README.md`

`_archive-index.md` 只能反映「归档器处理过的记录」（来自 `state.json`），盘上已有的历史文件、人工放进去的番剧它都看不见。所以另开一个**扫描云盘目录**的总览：

- 事实来源是**云端目录本身**（OpenList `/api/fs/list` 逐层扫描），不依赖本地状态；
- 位置：`<mount>/Anime/README.md`（覆盖原有的占位 README），整文件覆盖上传；
- 频率：`libraryIndex.intervalHours`（默认 24h），由 `anime-library-index.timer` 驱动，另在开机 10 分钟后跑一次；
- 只读扫描 + 上传一个小文件，所以 `dryRun = true` 时也照常执行。

结构：先一段汇总（部数 / 季数 / 集数 / 总体积），再是「番剧 × 季数 × 集数」总表，最后是分季明细表。集数按文件名 `SxxExx` 去重统计，视频扩展名之外的（字幕、封面）不计入集数但计入体积。没有 `Season NN` 子目录的番剧归入「未分季」。

```markdown
# 番剧库总览

- 扫描目录：`/Private/OneDrive/Anime`
- 最后更新：2026-11-21 19:48 +0800
- 合计：**3** 部 / **3** 季 / **10** 集 / 10.60 GiB

| 番剧 | 季数 | 集数 | 体积 |
| --- | ---: | ---: | ---: |
| Jujutsu Kaisen | 1 | 7 | 2.94 GiB |
```

OpenList 的 Markdown 预览直接渲染表格，不需要额外前端。

### D12 本地清理与“孤儿文件”兜底

归档成功（上传 + 校验通过）后立即删本地：

- `stage()` 先把文件 `move` 进 `<downloadRoot>/Anime/<番名>/Season NN/`（同分区 rename，瞬间完成），上传从暂存区读；
- 所有目标都成功后才 `cleanup()` 删除暂存副本并回收空目录；任一目标失败就保留文件，下一轮重试；
- `purgeLeftovers = true` 时额外删除该种子里没被归档的剩余文件（`.aria2` 控制文件、`<infohash>.torrent`、临时文件）。字幕与字体包已进入归档计划（放在 `Extra/`），不再算“剩余文件”。

两个容易丢数据的点，已在代码里堵住：

1. **`upload_skip_existing` 必须校验大小**。上传中断会在云盘留下 0 字节占位文件，旧逻辑只看「同名文件存在」就跳过，接着把本地副本删掉——等于永久丢集。现在大小不一致会强制重传（实测 E51 的 670 MB mkv 就是这样补回来的）。
2. **aria2 重启会丢已完成任务记录**。归档器的输入是 `aria2.tellStopped`，记录一丢，那集就永远不会被归档（文件安静躺在下载区）。`orphanScan.enable = true` 时每轮额外扫描下载区：
   - 跳过 aria2 记录里仍存在的文件（含活跃/等待/停止）；
   - 跳过带 `<file>.aria2` 控制文件的（还在下载）；
   - 只处理 `mtime` 超过 `orphanScan.minAgeMinutes`（默认 60）的文件；
   - 按父目录合成一条虚拟种子记录（`gid = orphan-<sha256[:16]>`），走同一条 `plan_files` → `stage` → `upload` → `cleanup` 流水线。

`settle_signature()` 也做了对应回退：文件已被搬进暂存区时用暂存副本的大小参与稳定窗口判定，否则这类任务会永远卡在“等待稳定”状态（实测 E49/E51 就卡了半小时）。

## 6. 数据流与状态机

```text
[AB] RSS 解析 → 挂号番剧 → addUri(隧道 → aria2, dir=/var/lib/anime/downloads)
  ↓
[aria2] waiting → active → complete（seed-time=0，无做种）
  ↓
[AR] ① DISCOVER  tellStopped/tellStatus 找到 status=complete 且本地文件存在
    ② SETTLE    连续 2 次采样（间隔 180s）文件集合与大小一致
    ③ NAMING    取 AB 元数据 → mv 到 Anime/<Title>/Season NN/<Title> SNNENN.ext
                  非视频文件 → Anime/<Title>/Season NN/Extra/
    ④ UPLOAD    PUT /api/fs/put（逐文件，先正片后字幕）
    ⑤ VERIFY    fs/get 比对 size
    ⑥ CLEAN     删本地文件 → removeDownloadResult(gid)
    ⑦ RECORD    state.json + 追加索引行 → 触发索引重算
  ↓
  ARCHIVED

异常：
  UPLOAD 失败 → RETRY(1/5/15/60/240 min) → 超 5 次 → HOLD（全局停止 addUri）+ 邮件
  隧道断开 → AB 下发失败，aria2 继续跑；重连后 AB 自动重试
  磁盘水位 → 不领新任务 / 全停 + 邮件
  月流量预算耗尽 → HOLD 至次月 1 日 00:05 + 邮件
  OneDrive 容量水位 > 85% → 只告警；> 95% → HOLD + 邮件
```

`state.json` 字段：`gid`、`infohash`、`releaseName`、`title`、`season`、`episode`、`files[]`（原名/新名/size）、`targets{onedrive:{state,size}}`、`attempts`、`bytesUploaded`、`updatedAt`。它是删除前最后一道校验的唯一事实来源。

## 7. 阈值与预算

| 项 | 值 | 依据 |
| --- | --- | --- |
| 归档区 qgroup 限额 | **8 GiB** | 14 GiB 可用，系统留 6 GiB |
| `lowWaterGiB` / `criticalGiB` | 4 / 2.5 | 低于 4 停领新任务，低于 2.5 全停 |
| aria2 并发 | `max-concurrent-downloads = 1` | 盘小；串行也避免上传与下载抢带宽 |
| aria2 连接 | 单服务器 8，split 16 | 现有模块值，保留 |
| aria2 `disk-cache` | **16 MiB** | 1.92 GiB 机型，缓存从内存里抠 |
| aria2 `bt-max-peers` | **30** | 降内存与 conntrack |
| `settleSeconds` | 180 | 覆盖 move/字幕后到 |
| 轮询间隔 | 30 s | — |
| `retryMax` | 5 | 指数退避 1/5/15/60/240 min |
| 月下载预算 | **200 GiB** | 用户指定；对应流量约 400 GB，见第 8 节 |
| 每日上传预算 | 300 GiB | 未来接 GDrive 时直接生效 |
| `MemoryHigh` / `MemoryMax`（archiver） | **96M / 160M** | 纯标准库 + curl 子进程，Python 堆很小 |
| `MemoryMax`（aria2） | 128M | 并发 1 |
| `MemoryMax`（OpenList 容器） | 建议补 320M（当前未限） | Go 流式上传仍需堆 |
| journald `SystemMaxUse` | 200 MB | 30 GiB 盘必须限制 |
| nix GC 保留 | 3d（HK 专用收紧） | 现有 weekly/7d 在 14 GiB 余量下偏松 |

### 7.1 内存预算（1.92 GiB 机型）

`free` 实测：总计 1.92 GiB、可用 875 MiB、swap 已用 542 MiB（zram 压缩 swap）。现有负载（OpenList、vaultwarden、postgres、nextbridge、caddy、gost、frp、easytier、rustdesk、mailer…）已接近上限，新增常驻必须逐项抠：

| 组件 | 增量 RSS 目标 | 手段 |
| --- | --- | --- |
| aria2 | 40–60 MiB | `disk-cache=16M`、`bt-max-peers=30`、并发 1、`file-allocation=none`（现有） |
| anime-archiver | 35–50 MiB | **纯 Python 标准库**（`urllib`/`json`，不装 requests），大文件传输交给 `curl` 子进程（curl 流式，RSS ~8 MiB，零缓冲） |
| AB 隧道 ssh | ~6 MiB | — |
| **合计** | **≤ 110 MiB** | 相对 875 MiB 可用余量，仍留 700+ MiB 给 page cache 与 OpenList |

配套原则：

- 三个 unit 各自设 `MemoryMax`（见上表），用 cgroup 硬限，避免单个进程把整机拖进 OOM。
- 归档与下载会重叠：aria2 并发 1，一集完成后立即进入上传，此时 aria2 仍在拉下一集。重叠窗口内存是**叠加**的，因此不能给两者一个共用额度。
- OpenList 是 Go 程序，上传大文件时堆会涨；当前容器**没有**内存限制，建议补 `MemoryMax=320M`（超出会回落为更小的流式缓冲，只降低吞吐，不会失败）。
- 若实测仍吃紧：保持 `maxParallelUploads = 1`（默认值），并降低 `settleSeconds` 采样时的文件列表读取量。

## 8. 容量与流量模型（本方案的真瓶颈）

**流量**（单目标）：`T = 2D = 400 GB/月`，占 600 GB 配额 **67%**。无论野草云按双向还是仅出站计量都安全，余下 200 GB 留给突发并发与 DHT/announce 零散流量。

**下载量**（用户指定 200 GiB/月）：每月能追多少集取决于实际单集体积（**不做质量限制**）：

| 源质量 | 单集体积 | 200 GiB ≈ | 季番数（12 集/部） |
| --- | --- | --- | --- |
| 1080p HEVC | ~0.8 GiB | ~250 集 | ~20 部 |
| 1080p AVC | ~1.3 GiB | ~154 集 | ~12 部 |
| 720p HEVC | ~0.4 GiB | ~500 集 | ~40 部 |

**容量**（OneDrive 家庭版 1 TB）：`1024 / 200 ≈ 5.1` → **约 5 个月灌满**。这个时间**与单集体积无关**，只与总体积有关；单集体积只决定这 5 个月里能装多少集。

> **结论：容量是长期瓶颈，流量不是。** 600 GB 月流量下用量仅 400 GB/67%，很宽裕；而 1 TB 空间约 5 个月见底。订阅质量不做任何限制（不锁分辨率/编码），容量到时直接扩容。

长期路线（用户已决定，仅此一条）：

1. **到期直接扩容 OneDrive**。归档器不做任何云端保留策略 —— 空间满时 `HOLD` + 邮件，等人工扩容；不自动删旧集、不做多账号分层搬迁（这些不在本次设计范围内）。

## 9. NixOS 落地结构

### 9.1 模块改动

```text
modules/server/aria2/nixos.nix        # 扩展现有模块（新增选项，不破坏 OpenList 离线下载用法）
modules/server/anime-archive/
  nixos.nix                           # rhen.services.animeArchive.*
  archiver.py                         # 非 magic 文件，由 nixos.nix 显式引用
modules/server/autobangumi/
  nixos.nix                           # rhen.services.autobangumi.*（OCI + SSH 隧道 unit）
```

`archiver.py` 是普通文件（不是 magic 文件），由 `nixos.nix` 通过 `writePythonApplication` 或 `writeShellApplication` 引入，符合仓库"普通辅助文件必须由 magic 文件显式导入"的约定。

### 9.2 选项签名（草案）

```nix
# 现有模块扩展
rhen.services.aria2 = {
  # …既有选项…
  forceSave = true;                 # 使已完成任务在重启后仍可见，便于补归档
  maxConcurrentDownloads = 1;       # 覆盖默认 5，适配 14 GiB 盘
  diskCacheMiB = 16;
  resumeOnRestart = true;           # save-session / input-file 落盘，重启后续传
  rpcListenAll = false;             # 默认值；AriaNg/AB 都经 Caddy 反代访问，不需公网监听
  rpcAllowedSources = [ ];          # 非空时生成 nftables 源地址白名单（备用）
};

rhen.services.animeArchive = {
  enable = false;
  downloader = "aria2";             # aria2 | qbittorrent
  downloadRoot = "/var/lib/anime";  # 与 aria2 downloadDir 同目录树
  aria2 = {
    rpcUrl = "http://127.0.0.1:6800/jsonrpc";
    secretSecret = "aria2-rpc-secret";   # 复用现有 sops 键
  };
  openlist = {
    url = "http://127.0.0.1:5244";
    tokenSecret = "openlist-api-token";
  };
  targets = [
    {
      name = "onedrive";
      mount = "/onedrive/Anime";
      quotaGiB = 1024;              # 用于容量水位推算
    }
  ];
  naming = {
    template = "{title} S{season:02}E{episode:02}{ext}";
    seasonDir = "Season {season:02}";          # 目录：/Anime/<标题>/Season NN/
    extraDir = "Extra";             # 字幕/字体/封面放 Season NN/Extra/
    includeYear = false;            # 目录名不带年份
    subtitleSuffix = true;          # 杜鹃的婚约 S01E07.chs.ass
    keepGroupTag = false;           # 不保留 [Lilith-Raws] 之类字幕组前缀
    abMetadata = true;              # 优先用 AB 元数据，失败退回正则
  };
  index = {
    enable = true;
    path = "/onedrive/Anime/_archive-index.md";
    unnamedPath = "/onedrive/Anime/_unnamed.md";   # 命名失败单独成文
    flushEvery = 10;
    flushDailyHours = 24;
  };
  settleSeconds = 180;
  retryMax = 5;
  lowWaterGiB = 4;
  criticalGiB = 2.5;
  monthlyDownloadBudgetGiB = 200;   # 用户指定；流量 ≈ 2× = 400 GB/月
  maxParallelUploads = 1;
  uploadBackend = "openlist";       # openlist | rclone
  verifyMode = "size";              # size | hash
  dryRun = true;                    # 首次上线必须 true
};

rhen.services.autobangumi = {
  enable = false;
  port = 7892;
  image = "ghcr.io/estrellaxd/auto_bangumi:latest";
  dataDir = "/var/lib/autobangumi";
  pullPolicy = "missing";
  downloader = {
    type = "aria2";
    url = "http://127.0.0.1:16800/jsonrpc";   # 隧道本地端口
    secretSecret = "aria2-rpc-secret";
    savePath = "/var/lib/anime/downloads";    # HK 上的绝对路径，AB 无需本地存在
  };
  tunnel = {
    enable = true;
    host = "85.189.59.172";
    sshPort = 22222;
    user = "rhencloud";
    remoteRpcPort = 6800;
    localPort = 16800;
    keySecret = "ab-aria2-tunnel-key";
    knownHostsFile = "/var/lib/ab-tunnel/known_hosts";
    hostKey = "ssh-ed25519 AAAA...";    # 设置则严格校验；null 则 accept-new
  };
  plugins = {
    enabled = [ "ingest-filters" ];
    disabled = [ "rename" "hardlink" "media-server-refresh" ];
  };
  seedConfig = null;                # 非 null 时仅在 config.json 缺失时播种一次
  extraOptions = [ ];
};
```

实现要点（已落地）：

- 容器固定 `--network=host`：AB 只需访问本机回环上的隧道端口，无需端口映射，也避免桥接网络下容器看不到宿主 `127.0.0.1`。
- 隧道是独立的 `ab-aria2-tunnel.service`：`ssh -N -T -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o BatchMode=yes -i <sops 私钥> -L 127.0.0.1:16800:127.0.0.1:6800`，`Restart=always`、`MemoryMax=32M`（实测单条 ssh 约 6 MiB）。
- `knownHostsFile` 放在 tmpfiles 建的 `/var/lib/ab-tunnel`（0700）；给 `hostKey` 则另起 `ab-tunnel-known-hosts` oneshot 写入并以 `StrictHostKeyChecking=yes` 连接。
- `seedConfig` 走 `sops.templates` 渲染到 `<dataDir>/seed/config.json`，`autobangumi-seed.service` 仅在 `config/config.json` 不存在时 `install -m 0600` 复制一次；AB 之后自行改写，容器 unit `Requires` 该 oneshot。
- 容器与 seed 均 `RequiresMountsFor = <dataDir>`，避免在未挂载的空目录上初始化。

`assertions` 建议加两条：

- `length targets > 1 → monthlyDownloadBudgetGiB ≤ 130`（D9 的耦合：双写把流量变 `3D`）；
- AB REST 不可达时只告警不阻塞（避免 AB 挂掉把归档一起拖死）。

### 9.3 主机改动

| 主机 | 改动 |
| --- | --- |
| `yc-hk-1` | **已落地**：`rhen.services.aria2 = { enable = true; downloadDir = "/var/lib/anime/downloads"; maxConcurrentDownloads = 1; btMaxPeers = 30; diskCacheMiB = 16; forceSave = true; resumeOnRestart = true; }`（RPC 只监听 `127.0.0.1:6800`）；Caddy 新增 `aria.rhen.cloud`（AriaNg + `/jsonrpc` 同源反代，橙云 + Cloudflare Access）与 `aria-rpc.rhen.cloud`（灰云，`@sg remote_ip 81.31.208.183` 才反代，其余 `abort`）；`rhen.services.animeArchive = { enable = true; targets = [{ name = "onedrive"; mount = "/Private/OneDrive/Anime"; quotaGiB = 1024; }]; index.path = "/Private/OneDrive/Anime/_archive-index.md"; index.unnamedPath = "/Private/OneDrive/Anime/_unnamed.md"; }`；`services.fast-nix-gc.deleteOlderThan = "3d"`（`_common/nix/nixos.nix` 的默认值改为 `lib.mkDefault "7d"`，主机侧用普通赋值覆盖，**不用 `mkForce`**）。子卷 `8 GiB`、tmpfiles、journald `200M` 由 `anime-archive` 模块在 `smallDiskMode = true` 下自己完成 |
| `hd-sg-1` | **不改仓库**：实际系统是 **Ubuntu**，AutoBangumi 已由用户用 docker compose 部署。`modules/server/autobangumi` 保留但默认关闭（`enable = false`），等它将来变成 NixOS 主机再启用。隧道改为 Ubuntu 侧 systemd 单元，见 §10.4 |
| `deploy/default.nix` | 已补上 `hd-sg-1` 节点（`81.31.208.183`，`-p 22222`，`sshUser = "rhencloud"`，`activationTimeout = 900`），`checks/deploy-nodes-schema` 同步纳入 |

归档目标为什么不是 `/Public/Anime`：那是 OpenList 的 `Alias`（合并 `/Private/OneDrive/Anime` 与 `/Private/Aliyun/Anime`，`put_conflict_policy = all`），写入会同时扇到两个云，上行流量翻倍，直接冲破 200 GiB 预算。因此归档器只写真实存储 `/Private/OneDrive/Anime`。

落地实测（2026-11-21）：

- HK 根文件系统**是 btrfs**，子卷 `/var/lib/anime` 已创建，qgroup `0/261` 的 `Max referenced` 为 `8.00GiB`（`btrfs quota enable /` 需要一次 rescan，约几十秒）。
- 首启踩过一个坑：aria2 模块的 tmpfiles 会在 sysinit 阶段先建出 `/var/lib/anime/downloads`，`btrfs-anime-setup` 看到「目录已存在且非空」就跳过子卷创建，限额根本没地方挂。已修：目录里**只有空目录**时清空后照样建子卷，只有真的有文件才放弃。
- 内存实测：`anime-archiver` 峰值 `31.2M`，`aria2` 常驻几十 MB，1.92 GiB 机型下合计仍有余量。
- dry-run 端到端验证：用 aria2 RPC 拉了一个 2 MB 文件，归档器在 `settleSeconds` 后输出 `dry_run_plan`，`status.json` 中 `dryRun = true`、`diskFreeGiB ≈ 14`。非种子（无 `bittorrent` 段）任务会退回「按目录名当发布名」，因此显示为 `_unnamed`——这是预期行为，真实种子走 `bittorrent.info.name`。

部署注意：`deploy-rs` 会在复制 `home-rhencloud` 那个 **1.95 GB** 的 Home Manager 闭包时被公网链路反复 reset（`Broken pipe`），而 `system` profile 的闭包本身是能传完的。可行做法是

```bash
nix build "path:$PWD#nixosConfigurations.yc-hk-1.config.system.build.toplevel"
env -u all_proxy -u http_proxy -u https_proxy NIX_SSHOPTS="-p 22222" \
  nix copy --to ssh://rhencloud@85.189.59.172 --no-check-sigs <toplevel>
ssh -p 22222 rhencloud@85.189.59.172 \
  'sudo nix-env -p /nix/var/nix/profiles/system --set <toplevel> && sudo <toplevel>/bin/switch-to-configuration switch'
```

即 system 单独手动激活（home 侧这次没有改动，旧的 home generation 继续有效）。

新增的离线检查（`nix flake check` 会自动跑）：

- `checks/anime-archive`：`archiver.py` 纯函数回归（种子名解析、语言后缀、字符清洗、命名模板、文件计划、命名失败兜底、索引与失败清单渲染），不联网不落盘。

### 9.4 Secrets 清单

| 键 | 文件 | 用途 |
| --- | --- | --- |
| `aria2-rpc-secret` | `secrets/hosts/yc-hk-1.yaml` | aria2 JSON-RPC token（SG 与 HK 两侧都用；HK 侧经 `rpcSecretFile`） |
| `openlist-api-token` | `secrets/hosts/yc-hk-1.yaml` | 归档器调用 OpenList API |
| `ab-aria2-tunnel-key` | `secrets/hosts/yc-hk-1.yaml` + `secrets/hosts/hd-sg-1.yaml` | ~~SSH 隧道私钥~~（已弃用：改用公网 RPC + 源地址白名单，两个文件里的这两个键可以删） |

`.sops.yaml` 已为 `hd-sg-1` 与 `yc-hk-1` 配好 creation rule。**已写入的键**：`aria2-rpc-secret`（32 位 hex，两侧共用）、`openlist-api-token`（取自 OpenList `x_setting_items.token`）、`ab-aria2-tunnel-key`（ed25519，已随隧道方案弃用，可删）。

落盘规则（遵循 AGENTS.md）：

- 一律用 `snowveil.sops.secret { source = "host"; host = "..."; }`，不手写 `self.outPath + "/secrets/..."`。
- 归档器与 AB 的凭据走 `sops.templates` → `/run/secrets/templates/`，服务通过环境变量或命令行参数读取。

## 10. 配置示意

### 10.1 aria2（在现有模块设置基础上增补）

```conf
dir=/var/lib/anime/downloads
continue=true
file-allocation=none
disk-cache=16M
max-concurrent-downloads=1
max-connection-per-server=8
split=16
min-split-size=1M

# 做种策略 none
seed-time=0
seed-ratio=0

# BT 相关
follow-torrent=true
bt-save-metadata=true
bt-max-peers=30
enable-dht=true
enable-peer-exchange=true

# 可恢复性
force-save=true
save-session=/var/lib/aria2/session
save-session-interval=60
input-file=/var/lib/aria2/session

rpc-listen-all=false
rpc-listen-port=6800
```

> 现有模块已包含 `seed-time=0`、`follow-torrent`、`bt-save-metadata`、`rpc-listen-all=false`；本次只需增补 `force-save`、session 路径、并发与缓存。`User = root` 的现有设定保留（`file-allocation=none` 时不需要，但保留可避免日后换 NTFS 挂载点再踩权限坑）。

### 10.2 AutoBangumi 下载器实例（4.0 `plugins.instances`）

```jsonc
{
  "plugins": {
    "instances": {
      "hk-aria2": {
        "kind": "downloader",
        "type": "aria2",
        "settings": {
          "rpc_url": "http://127.0.0.1:16800/jsonrpc",
          "rpc_secret": "<from sops>",
          "dir": "/var/lib/anime/downloads"
        }
      }
    },
    "slots": { "downloader": "hk-aria2" },
    "enabled": ["ingest-filters"],
    "disabled": ["rename", "hardlink", "media-server-refresh"]
  }
}
```

> AB 4.0 的插件实例 schema 以实际版本为准；此处给出的是结构示意，落地时以 AB 导出的 `config.json` 为准。

### 10.3 归档器核心流程（伪代码）

```python
for t in aria2.completed():                       # tellStopped + tellStatus
    if not local_files_exist(t):            continue
    if not stable(t, settle_seconds=180):   continue      # 两次采样一致
    if disk_free() < low_water:             break         # 不领新任务
    if month_download_exceeded(200):         hold("budget"); break

    task = load_or_create(t)
    meta = ab_metadata_for(t) or parse_release_name(t.name)
    dst  = move_and_rename(t.files, meta)                # ③ 本地 mv

    for f in dst.files:                                   # ④
        if exists_and_same_size(target(f)): continue      # 幂等
        put_stream(target(f), f)
        require(size(target(f)) == size(f))               # ⑤

    delete_local(dst);  aria2.removeDownloadResult(t.gid) # ⑥
    record(task);  index.maybe_flush()                    # ⑦
```

### 10.4 hd-sg-1 侧配置（Ubuntu，无隧道）

SG 上**不需要**装任何隧道或私钥：AB 直连 `https://aria-rpc.rhen.cloud`（灰云，Caddy 只放行 SG 的 `81.31.208.183`）。

AB 4.x 的 WebUI 操作（改完点「保存并重启」）：

| 位置 | 设置 |
| --- | --- |
| 设置 → 下载设置 | 类型 `aria2`；地址 `https://aria-rpc.rhen.cloud`（**不要带 `/jsonrpc`**，AB 会自己拼）；密码填 `aria2-rpc-secret`（用户名留空，aria2 会忽略）；下载地址 `/var/lib/anime/downloads`；SSL 开 |
| 设置 → 番剧管理 | 重命名方式选 `none`（重命名归归档器，避免两边抢文件） |
| 设置 → 插件 | 关闭 `rename`、`hardlink`、`media-server-refresh`，只留 `ingest-filters` |

AriaNg 里填的则是完整地址：`https://aria.rhen.cloud/jsonrpc` + 同一个 token（页面本身走 Cloudflare Tunnel + Access）。

连通性自检（在 SG 上跑）：

```bash
curl -s -X POST https://aria-rpc.rhen.cloud/jsonrpc \
  -d '{"jsonrpc":"2.0","id":1,"method":"aria2.getVersion","params":["token:<rpc-secret>"]}'
# 期望：{"id":1,"jsonrpc":"2.0","result":{"version":"1.37.0",...}}
```

如果返回超时/连接被断开而不是 `Unauthorized`，说明 Caddy 的 `remote_ip` 没匹配上 —— 确认 SG 的真实出口 IP 是否就是 `81.31.208.183`，不一致就改 `hosts/yc-hk-1/default.nix` 里 `aria-rpc` vhost 的 `@sg remote_ip`。

注意：**不要**让 AB 自动清理已完成的 aria2 任务（`removeDownloadResult`），否则归档器拿不到任务记录就归档不到；清理由归档器在归档成功后自己做。

## 11. 落地前必须验证的 4 项

| 编号 | 验证内容 | 方式 | 失败时降级 |
| --- | --- | --- | --- |
| **S1** | AB 4.0 是否提供 `type: "aria2"` 下载器，且能通过 HTTPS 反代 `addUri` 并正确设置 `dir` | SG 上起容器 + 手工加一部番，`journalctl` 看 RPC 调用 | 退回 qBittorrent 后端（`downloader = "qbittorrent"`），命名走 `renameFile` |
| **S2** | aria2 `seed-time=0` 下，完成任务的 `status` 变化与 `tellStopped` 可见性；`force-save` 重启后是否仍可见 | 单集试跑 + 重启服务后 `tellStopped` 对比 | 归档器改用 `on-download-complete` 钩子（`--on-download-complete`）而不是轮询 |
| **S3** | OpenList `PUT /api/fs/put` 到 OneDrive 的实测吞吐与断流重试；1.4 GiB 单文件上传耗时 | 3 次计时 + 人为断网（✅ 已完成上传/校验/删除闭环，还差 1.4 GiB 计时） | 切 `uploadBackend = "rclone"` |
| **S4** | 归档器从 AB REST 取季集元数据的正确率（对比 10 部番的实际命名） | `dryRun = true` 跑 24h，人工核对输出清单 | 关掉 `abMetadata`，纯正则；或补规则表 |

## 12. 失败模式与恢复

| 现象 | 影响 | 检测 | 处置 |
| --- | --- | --- | --- |
| SSH 隧道断开（已弃用该方案） | — | — | 现改为 Caddy 反代，不再需要隧道 |
| aria2 崩溃/重启 | 下载中断 | 服务状态 | `force-save` + session 恢复；已完成记录丢失时由 `orphanScan` 扫描下载区兜底 |
| OpenList 挂掉 | 归档停摆、本地堆积（受 8 GiB 限额保护） | 连续 N 次 5xx | 保留文件、`HOLD` + 邮件；`pull = "missing"` 避免拉镜像卡死 |
| OneDrive 403/限流 | 上传失败 | 响应码 | 指数退避；连续 3 日失败 → 邮件 + 全局 HOLD |
| OneDrive 容量满 | 上传 507/配额错误 | `quotaGiB` 水位推算 | HOLD + 邮件，等人工清理 |
| 磁盘水位告警 | 下载失败 | `free` 水位 | 停领新任务 → 全停 + 邮件 |
| 月下载量将尽 | 超下载预算（流量随之超） | 归档器自记 `bytesDownloaded` | 达 200 GiB 即 HOLD 至次月 1 日 |
| 命名失败/元数据缺失 | 无法归档 | 命名阶段异常 | 保留原文件名上传 + 记录到 `_unnamed.md`，不阻塞队列 |
| 文件名非法字符 | 上传 400 | 响应码 | sanitize `? * : < > \| "` 与控制字符，原名记入 state |
| 同一集重复添加 | 云盘重复文件 | size + 路径去重 | AB「单番发布偏好」锁字幕组/分辨率；归档器 size 校验兜底 |

## 13. 观测、告警与备份

- **监控**：`beszel-agent`（HK 已开，SG 需开启）。归档器每轮写 `/var/lib/anime-archive/status.json`：队列深度、上次成功时间、当日/当月已用流量、OneDrive 已归档体积占比、HOLD 原因。
- **告警**：复用 HK 的 `rhen.services.mailer`，事件：上传失败达上限、HOLD、磁盘水位、流量/容量水位。去重窗口 30 分钟。AB 侧可用通知插件推 Telegram。
- **日志**：全走 journald（`SystemMaxUse=200M`），JSON 行格式。
- **备份**：`state.json`、`/var/lib/autobangumi/config`、`/var/lib/openlist/data.db` 纳入现有 `attic-push.sh`。
- **可重建性**：aria2 的 `.torrent` 与 session 无需备份（丢了重下）；`state.json` 丢失也不会重复上传（size 去重兜底），但会丢失索引历史 —— 索引文件在云盘上，可作为二次来源。

## 14. 分阶段落地

| 阶段 | 内容 | 验证 |
| --- | --- | --- |
| P0 | S1–S4 验证（可用手工 podman/docker 起 AB，不进仓库） | 第 11 节 |
| P1 | 扩展 `modules/server/aria2`：并发 1、force-save、session、缓存 | `nix run .#build -- yc-hk-1`；`curl 127.0.0.1:6800/jsonrpc -d '{"jsonrpc":"2.0","id":1,"method":"aria2.getVersion"}'` |
| P2 | 磁盘治理先行：journald 200M、qgroup 8 GiB 子卷、GC 收紧到 3d | `btrfs qgroup show /`；`df -h /`；`journalctl --disk-usage` |
| P3 | `modules/server/anime-archive`，`dryRun = true` 跑满 24h（只打印将 mv/上传/删除的清单） | `journalctl -u anime-archiver -f` + 人工核对 |
| P4 | `modules/server/autobangumi` + SSH 隧道；插件只留 `ingest-filters` | `ssh -L 16800:127.0.0.1:6800 …` 手工验证 RPC；AB WebUI 下载器连通 |
| P5 | 单部番端到端（`dryRun = false`）：核对云盘路径/文件名/size、本地已删、索引已更新 | 云盘 `list` + `df -h /` + `state.json` |
| P6 | 全量订阅 + 告警 + 备份纳入；`nix flake check --all-systems` + AGENTS.md 检查流程 | 全套 |

代码侧进度（2026-11-21 晚）：P1–P3 已就绪并**已部署到 `yc-hk-1`**（`switch-to-configuration switch` 完成），`aria2`、`btrfs-anime-setup`、`anime-archiver` 三个单元均 `active`；`dryRun` 仍为 `true`。`hd-sg-1` 是 Ubuntu，AB 已手工部署，仓库侧不启用 `autobangumi` 模块。

已实测确认的非代码结论：

- OpenList `PUT /api/fs/put` 到 `/Private/OneDrive/Anime` 返回 200，`fs/get` 返回的 `size` 与本地字节数一致，删除也成功（S3 的核心路径已验证，吞吐量尚未计时）。
- `/Public/Anime` 是 `Alias`（OneDrive + Aliyun，`put_conflict_policy = all`），不能当归档目标。
- `hd-sg-1`（`81.31.208.183`）22/22222 端口能建 TCP 但无 SSH banner，仓库里那个 NixOS 主机目录暂时无法 deploy。

## 15. 已关闭的未决项

全部参数已确认，无待确认事项：

- 流量计量口径：无所谓，400 GB/月两种口径都在 600 GB 内。
- 番剧目录：**不带年份**，固定 `/Anime/<标题>/Season NN/`。
- 云端保留策略：**不做**。空间满则 `HOLD` + 邮件，人工扩容。

---

建议先做 **P1 + P2**：aria2 扩展与磁盘治理风险最低、立刻见效，且是后续所有阶段的前提。`dryRun` 必须跑满 24 小时再放开写与删。
