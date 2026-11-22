# 自建 Nix 缓存 + 自动化 CI 发布 设计方案

> 状态：已落地（v5）——服务端已部署，自动更新管道已写。
> 缓存主机：`hd-sg-1`（Hostinger 新加坡，`81.31.208.183`）——**保留 Debian 13，不重装 NixOS**。
> 域名：`https://cache.rhen.cloud`。
> v4 变更：新增「高频自动更新打包软件版本 + nix flake update + 构建 + 推缓存」的完整管道设计，并附 23 个自有包的自动化可行性实测。
> v5 变更：实际机器是 Debian 13 + 1Panel，80/443 归 OpenResty，不跑 Caddy；全部候选包跑完一轮实测（9 个全自动）。

## 目录

1. 目标与非目标
2. 现状与约束
3. 空间模型：只缓存上游没有的（实测）
4. 为什么服务端软件不能更「轻」（实测）
5. 选型：Attic
6. 缓存服务部署（Debian + Docker + AcePanel 反代）
7. 客户端接入
8. 定时构建与推缓存（拿「最新 flake」的缓存）
9. **高频自动更新：包版本 + nix flake update + 构建 + 推缓存**
10. 自有包自动化可行性实测
11. 落地结构
12. 分阶段实施
13. 运维与失败模式
14. 待确认

---

## 1. 目标与非目标

目标：

- `hd-sg-1` 上跑一个可写的 Nix 二进制缓存 `https://cache.rhen.cloud`，**只缓存上游拿不到的路径**。
- CI 定期（高频）做三件事：**升级自有包版本 → `nix flake update` → 构建 → 推缓存**。
- 本机 `nixos-rebuild switch` 时**纯替换、零编译**，不用等某台机器先编译上传。
- 自动化必须有护栏：构建失败就**不合并**，坏掉的包自动回滚。

非目标：

- 不改 `hd-sg-1` 的操作系统；不写 NixOS 模块。
- 不做多租户/公开写权限；不做高可用。
- 不缓存 NixOS ISO / 全量 nixpkgs。

---

## 2. 现状与约束

| 事实 | 影响 |
| --- | --- |
| `hd-sg-1` 只能跑 Debian/Ubuntu + 1Panel，AB 用 docker compose 手部署 | 放弃 `hosts/hd-sg-1` NixOS 路线；`hosts/hd-sg-1/`、`deploy` 里的节点、`checks/deploy-nodes-schema` 的期望列表属于死配置，建议单独一次提交移除 |
| 80/443 由 AcePanel nginx 接管（2026-11-22 起；此前是 1Panel OpenResty） | 不跑 Caddy；atticd 只监听回环 8080，TLS 交给 AcePanel 站点 |
| 只能用 `root` + YubiKey（agent 里的 card key）登录，无 `rhencloud` 用户 | 部署时开一条 ControlMaster 复用连接，一次触碰跑完全部命令 |
| 已装 Docker + compose | 直接复用 |
| 无法 sops-nix / deploy-rs | 密钥服务器本地生成 + 仓库留加密灾备副本 |
| **仓库是 public** | GitHub Actions 分钟数**不限**（标准 runner），高频可行 |
| `publish-cache.yml` 只有 push 触发、`nixcache-oci` 的 `mode: flake` 构建整个 flake（很重） | 需改造：加 schedule、换 `attic push`、改显式构建 toplevel |
| `update-flake-lock.yml` 每周开 PR | 将被第 9 节的自动更新管道取代 |
| 全仓库**没有** `self.rev` / `dirtyRev` | 工作树无关改动不影响 hash，命中友好 |
| `wallpapers` 是 submodule | CI 里需 `submodules: false` + 用 `git archive`（见 9.3），避免拉 1 GB 图包 |
| 仓库 23 个自有包，`packages/` 自动发现 | 见第 10 节的自动化可行性分类 |

---

## 3. 空间模型：只缓存上游没有的

### 3.1 上游过滤是 Attic 的默认行为

`attic push` 自带 upstream cache filter：带 `cache.nixos.org-1` 等已登记上游 key 签名的路径直接跳过，日志形如 `(0 already cached, 45 in upstream)`。所以「只存上游没有的」不用自己实现，**前提是把在用的上游 key 都登记进缓存**（`--upstream-cache-key-name`，默认只有 `cache.nixos.org-1`）。

### 3.2 实测：`nixos-desktop` 系统闭包

| 分类 | 路径数 | NAR | 占比 |
| --- | --- | --- | --- |
| 上游已签名（自动跳过） | 3246 | 39.82 GiB | 78.3% |
| **无任何签名（会被推送）** | **1018** | **11.03 GiB** | **21.7%** |

再对那 1018 个路径逐个查 narinfo：236 个（23%）上游其实有（本地重编但产物相同），但**只占 0.21 GiB（2%）**；782 个真本地独有，占 **10.81 GiB（98%）**。→ 预查 narinfo 只省 2%，不值得写。

### 3.3 那 11 GiB 是谁

wpsoffice-cn 2.02G、feishu 1.67G、nvidia 全家桶 1.29G、vscode 0.99G、ant-browser 0.82G、wechat 0.70G、qq 0.60G、chrome 0.44G、zedg 0.41G、zen-beta 0.40G、slack 0.33G ≈ **9.2 GiB 桌面闭源大包**；自建包（niri、mihomo-meta、herdr 系列、rime 词库等）≈ **1.8 GiB**。

### 3.4 落盘估算

zstd + 全局分块去重后：桌面全闭包 ≈ **4–6 GiB**，30 天保留期稳态 5–8 GiB；只推服务器闭包 ≈ 0.7 GiB。大包版本不变时分块全命中，日常增量几百 MB。

---

## 4. 为什么服务端软件不能更「轻」（实测）

「nginx 直接服务静态目录」做不到「只存上游没有的」。本机实测：

```console
$ nix copy --no-recursive --to "file://$PWD/cache?compression=zstd&secret-key=..." \
    /nix/store/...-cowsay-3.8.4
error: cannot add '...-cowsay-3.8.4' to the binary cache
       because the reference '...-bash-5.3p20' does not exist
```

`file://`、`s3://` 都是 Nix 的 `BinaryCacheStore`，要求**被复制路径的所有引用已存在于目标缓存**。换真 store（`local?root=`）报 `does not exist in the Lix database`。→ 静态缓存只能整闭包复制（50.85 GiB 全传）。

**「只存上游没有的」这个需求本身，就要求服务端是能容忍悬空引用的索引式存储。**

---

## 5. 选型：Attic

| 方案 | 可写 | 只推子集 | 服务端签名 | 去重/GC | 部署重量 | 结论 |
| --- | --- | --- | --- | --- | --- | --- |
| nginx + 静态目录 | ✅ rsync | ❌ 实测不行 | 需私钥在 CI | ❌ 手工 | 最轻 | 排除 |
| nix-serve / harmonia | ❌ 只读 | — | ✅ | ❌ | Ubuntu 上还要装 Nix | 排除 |
| **Attic** | ✅ | ✅ 原生 | ✅ 推送方拿不到私钥 | ✅ CDC + zstd + GC | **1 容器 / 单层 83 MiB / SQLite / 无 Postgres** | **选它** |
| nixcache-oci（现有） | ✅ 仅 CI | ✅ | ✅ | ✅ | 依赖 GHCR | 过渡期并存 |
| Cachix | ✅ | ❌ 不滤上游 | ✅ | ✅ | 零运维 | 私有付费 |

Attic 的「重」只是概念多，运行面：镜像单层 83 MiB、空载内存 100–200 MB、备份只有一个 `server.db`、GC 内建。

---

## 6. 缓存服务部署（Debian + Docker + AcePanel 反代）

目标机实际系统是 **Debian 13 (trixie)**，4 核 / 5.8 GiB / 99 GiB，已装 Docker。
**80/443 由 AcePanel 自带的 nginx 接管**（2026-11-22 从 1Panel OpenResty 迁过来），
所以不跑 Caddy：atticd 只监听 `127.0.0.1:8080`，TLS 与对外入口交给 AcePanel 站点
（站点复用通配符 `*.rhen.cloud` 证书，面板自动续期）。

```text
nix ──https──▶ AcePanel nginx(80/443) ──http──▶ atticd 127.0.0.1:8080
```

### 6.1 `services/attic/docker-compose.yml`

```yaml
services:
  atticd:
    image: ghcr.io/zhaofengli/attic@sha256:317924e10e70416e69d401880bb71b3aae69b413ecafcfc54018f61929464526
    container_name: atticd
    command: ["-f", "/attic/server.toml", "--mode", "monolithic"]
    restart: unless-stopped
    env_file: [./atticd.env]
    volumes:
      - ./server.toml:/attic/server.toml:ro
      - /srv/atticd/data:/attic/data
      - /srv/atticd/storage:/attic/storage
    ports: ["127.0.0.1:8080:8080"]
    mem_limit: 512m
    logging: { driver: json-file, options: { max-size: "20m", max-file: "5" } }
```

### 6.2 `services/attic/server.toml`

```toml
listen = "0.0.0.0:8080"
allowed-hosts = [ "cache.rhen.cloud", "push.rhen.cloud" ]
api-endpoint = "https://push.rhen.cloud/"          # 推送/API（直连），结尾斜杠必须有
substituter-endpoint = "https://cache.rhen.cloud/" # 客户端拉取（走 CF）

[database]
url = "sqlite:///attic/data/server.db?mode=rwc"

[storage]
type = "local"
path = "/attic/storage"

[compression]
type = "zstd"
level = 19

[chunking]
nar-size-threshold = 65536
min-size = 16384
avg-size = 65536
max-size = 262144

[garbage-collection]
interval = "12 hours"
default-retention-period = "30 days"

[jwt.signing]
# 私钥不写在这里：由 atticd.env 的 ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64 提供
# （openssl genrsa -traditional 4096 | base64 -w0）
```

`api-endpoint` 决定 narinfo 里的 NAR URL，写错客户端 404。
`[jwt]` 与 `[chunking]` 都是「一旦有数据就不可改」的段：前者让所有令牌失效，后者掉去重率。

### 6.3 对外入口：双入口（下载走 CF，推送走直连）

**为什么不能只走 Cloudflare**：`attic push` 把**整个 NAR 当成一个 `PUT /_api/v1/upload-path` 请求体**
流式上传（服务端再分块去重，见 attic 源码 `client/src/api/mod.rs:172-199`），而 CF 免费版单请求
上限 100 MB，CF Pro 也只有 500 MB。实测：直连 PUT 95 MB → 通过，120 MB → `413 Payload Too Large`(cloudflare)。
GB 级包（ant-browser 807 MB、wpsoffice-cn 2 GB）永远推不上去。下载侧没有请求体大小限制，所以：

| 入口 | 域名 | 路径 | 用途 |
| --- | --- | --- | --- |
| 下载 | `cache.rhen.cloud` | CF 隧道（橙云 CNAME）→ cloudflared → `127.0.0.1:8080` | `substituters`、narinfo、NAR 下载 |
| 推送/API | `push.rhen.cloud` | 灰云 A → `81.31.208.183` → AcePanel nginx → `127.0.0.1:8080` | `attic login/push`、管理操作 |

服务端用两个独立配置项把它们分开（attlc 客户端一旦在 cache-config 里看到 `api-endpoint`，
就会把上传端点改写成它，见 `client/src/command/push.rs:155`——所以 `api-endpoint` 必须指向直连域）：

```toml
allowed-hosts = [ "cache.rhen.cloud", "push.rhen.cloud" ]
api-endpoint = "https://push.rhen.cloud/"          # 推送/API，结尾斜杠必须有
substituter-endpoint = "https://cache.rhen.cloud/" # 客户端拉取的 binary cache 端点
```

CF 面板操作（下载侧，需用户手工，token 隧道无 API）：

1. **删旧 DNS 记录**：`cache` 的 A 记录 `216.23.110.166`（东京源机，已返回 502）。
2. **Zero Trust → Networks → Tunnels** → 选 hd-sg-1 那条 → `⋯` → Configure → Public Hostname → Add：
   子域 `cache`、域 `rhen.cloud`、Type `HTTP`、URL `127.0.0.1:8080`。

推送侧（已执行）：

- DNS：`push` A 记录 → `81.31.208.183`，**灰云**（不走 CF 代理）。
- 站点：`services/attic/push.rhen.cloud.conf` → `/opt/ace/sites/push.rhen.cloud/config/site.conf`。
   关键指令：`client_max_body_size 0`、`proxy_request_buffering off`、`proxy_buffering off`、超时 3600s。
- 证书：直接复用 AcePanel 的 `cert_id=1`（`*.rhen.cloud` 通配符），拷到站点 `ssl/` 目录即可，
   续期由面板统一负责，不再单独跑 acme.sh。
- **必须在 AcePanel 的 `websites` 表登记**，否则站点能跑但不会出现在网页面板里：

```bash
SITE=/opt/ace/sites/push.rhen.cloud
mkdir -p "$SITE"/{config,ssl,public,log}
cp services/attic/push.rhen.cloud.conf "$SITE/config/site.conf"
cp /opt/ace/sites/git.rhen.cloud/ssl/fullchain.pem "$SITE/ssl/fullchain.pem"
cp /opt/ace/sites/git.rhen.cloud/ssl/privkey.pem   "$SITE/ssl/privkey.pem"
chmod 644 "$SITE/ssl/fullchain.pem"; chmod 600 "$SITE/ssl/privkey.pem"

cp /opt/ace/panel/storage/panel.db /root/panel.db.bak-$(date +%Y%m%d%H%M%S)
sqlite3 /opt/ace/panel/storage/panel.db <<'SQL'
INSERT INTO websites (name, type, status, path, ssl, cert_id, project_id, remark, created_at, updated_at)
VALUES ('push-rhen-cloud', 'proxy', 1, '/opt/ace/sites/push.rhen.cloud/public', 1, 1, 0,
        'attic 推送入口（直连，绕开 Cloudflare 100MB 单请求上限）',
        datetime('now'), datetime('now'));
SQL

/opt/ace/server/nginx/sbin/nginx -t && /opt/ace/server/nginx/sbin/nginx -s reload
```

两个上限对照（下载侧）：

| 限制 | 实际值 |
| --- | --- |
| CF 单请求 100 MB | 只影响推送，推送已绕开 |
| CF 请求超时 100 s | 应用层的短请求，不影响 |
| NAR 下载体积 | 不受 100 MB 限制，ant-browser 882 MB NAR 经 CF 正常下发 |

### 6.4 建缓存与令牌（已执行，记录实测结果）

```bash
attic cache create --public --priority 50 public \
  --upstream-cache-key-name cache.nixos.org-1 \
  --upstream-cache-key-name nix-community.cachix.org-1 \
  --upstream-cache-key-name hyprland.cachix.org-1 \
  --upstream-cache-key-name niri.cachix.org-1 \
  --upstream-cache-key-name noctalia.cachix.org-1 \
  --upstream-cache-key-name vicinae.cachix.org-1

# 容器内签发令牌必须带 -f，否则 atticadm 读不到配置：
#   Error: No such file or directory (os error 2)
docker compose exec atticd atticadm -f /attic/server.toml make-token \
  --sub ci --validity 2y --pull '*' --push 'public'

attic cache info public
```

实测结果：

| 项 | 值 |
| --- | --- |
| 缓存名 | `public`（同时也是公钥名） |
| 公钥 | `public:fZVnkMmYL+VX7gXj0zTSKU5dfAuZt7qUj6YtewfK0CU=` |
| Priority | 50 |
| 上游 key | cache.nixos.org-1、nix-community、hyprland、niri、noctalia、vicinae |
| 上游过滤 | 实测 push `hello` → `0 already cached, 5 in upstream`（正确跳过） |
| narinfo NAR URL | 相对路径 `nar/<hash>.nar`，所以拉取域与 API 域可以分离 |
| Binary Cache Endpoint | `https://cache.rhen.cloud/public`（= `substituter-endpoint` + 缓存名） |
| API Endpoint | `https://push.rhen.cloud/` |

令牌分两档：

- **admin**（仅本地应急）：`--pull '*' --push '*' --create-cache '*' --configure-cache '*'`
  `--configure-cache-retention '*' --delete '*' --destroy-cache '*'`，存服务器 `/root/.attic-admin-token`（0600）。
- **ci**（GitHub Actions）：`--sub ci --validity 2y --pull '*' --push 'public'`。

注意：**只给 `--pull`/`--push` 的令牌建不了缓存**，会报
`AccessError: User does not have permission to complete this action`；建缓存必须带 `--create-cache`。

配对：`ATTIC_PUSH_TOKEN` → GitHub Secret（已写入）；`atticd.env` 里的 RS256 secret 已加密备份到
`secrets/hosts/hd-sg-1.yaml` 的 `attic-token-rs256-secret-base64`（已回读比对一致）。

### 6.5 备份

`server.db` 里有**缓存签名私钥**，是唯一不可重建的东西。每日 `sqlite3 .backup` + rsync 到 `yc-hk-1`，保留 14 份。NAR 丢了能重推，私钥丢了所有客户端都要改公钥。

---

## 7. 客户端接入

`modules/_common/nix/nixos.nix` 与 `flake.nix` 的 `nixConfig` **两处同步**（已落地）：

```nix
substituters = [ "https://cache.rhen.cloud/public" ... ];
trusted-substituters = [ "https://cache.rhen.cloud/public" ... ];
extra-trusted-public-keys = [
  # Attic 的公钥名就是缓存名（这里是 public）
  "public:fZVnkMmYL+VX7gXj0zTSKU5dfAuZt7qUj6YtewfK0CU="
  ...
];
```

两个实测坑：

1. **Attic 的 substituter URL 必须带缓存名**：`https://cache.rhen.cloud/public`。
   写裸域名会一直 401（`{"code":401,"error":"Unauthorized"}`）。
2. **公钥名不是域名**，而是缓存名：`public:<base64>`。`attic cache info public` 直接给出完整串。

优先级 **50**（`cache.nixos.org` 是 40，越小越优先）：公共包继续命中镜像，只有私有路径落到 SG。必须用 `extra-trusted-public-keys`（`trusted-public-keys` 会被 flake `nixConfig` 覆盖，仓库里踩过）。

---

## 8. 定时构建与推缓存

### 8.1 为什么 CI 必须当推送方

「更新时直接吃缓存」意味着缓存里得有**你将要部署的那个闭包**。所以 CI 必须构建桌面闭包（L 档）并在你 switch 之前推好。

### 8.2 能命中的前提

本机求值的 `flake.lock` 必须和 CI 一致 → 流程是「**CI 合并 → 本机 pull → switch**」。本仓库没有 `self.rev`，所以工作树有未提交的无关改动不影响 hash；改动了 `modules/`/`hosts/` 就会 miss，属正常。

### 8.3 CI 必须把自建缓存配成 substituter

否则每轮都从零重编 11 GiB：

```yaml
- uses: DeterminateSystems/nix-installer-action@main
  with:
    extra-conf: |
      experimental-features = nix-command flakes
      substituters = https://cache.rhen.cloud https://cache.nixos.org https://nix-community.cachix.org https://hyprland.cachix.org https://niri.cachix.org https://noctalia.cachix.org https://vicinae.cachix.org
      trusted-public-keys = cache.rhen.cloud-1:... cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc= niri.cachix.org-1:W5oeOxxT1APmUFFJ9YlNYLwdSXL2Nmq1uvgrh5W6Fh0= noctalia.cachix.org-1:... vicinae.cachix.org-1:...
      max-jobs = 4
      cores = 4
      keep-going = true
```

有了它，`nix flake update` 后的构建只编**真的变了的**路径（nixpkgs rev 变了，但绝大多数 drv 的 hash 不变 → 全部命中缓存）。

---

## 9. 高频自动更新管道（核心新增）

### 9.1 一轮做什么

```text
cron(每 12 小时) / 手动
   │
   ├─ 1. nix flake update            （nixpkgs + 60 个 inputs）
   ├─ 2. 逐个 nix-update 自有包       （每个包：升级→构建→失败就单独回滚）
   ├─ 3. nixfmt
   ├─ 4. 构建 3 台主机 toplevel + packages   （缓存作 substituter，只编增量）
   ├─ 5. attic push（上游过滤自动生效）
   └─ 6. 建/更新 PR 「auto: 定期更新」，构建全绿则自动 squash-merge
        └─ 构建失败 → 保 old lock / 回滚坏包 → PR 不合并 + 评论失败原因
```

关键顺序：**先构建、先推缓存，再合并**。这样合并后你 pull 下来 switch 时缓存已经热了。

### 9.2 频率与合并策略（已定）

| 频率 | 每轮耗时（稳态） | 说明 |
| --- | --- | --- |
| 每 1 小时 | 5–15 min | 太吵：nixpkgs unstable 一天几十次提交，PR 会天天等你 |
| **每 12 小时** | 5–20 min | **已定**：包版本最多滞后半天，PR 频率低到可以无人值守 |
| 每 6 小时 | 5–20 min | 省事，包版本滞后半天 |

**仓库是 public → Actions 分钟数不限**，所以高频的唯一代价是 runner 排队（free 计划并发 10–20 job）。用 `concurrency.group` 保证不重叠。

补充（已定）：**包更新与 lock 更新彻底分开**——`auto-update.yml` 每 12 小时只升级 `packages/*` 并自动合并；`flake.lock` 继续由 `update-flake-lock.yml` 每周开 PR、**人工合并**。原因：包版本升级风险低（单包 + 独立 verify/rollback），nixpkgs 大版本变动需要人看一眼 diff。

### 9.3 `nix-update --flake` 的坑（实测）

在**脏 git 工作树**里跑 `nix-update --flake <pkg>` 会失败：

```
$ nix flake metadata --json     # 干净时 → {"path": "/nix/store/xxx-source", ...}
                                # 脏树时 → {"dirtyRevision": "...-dirty", ...}  ← 没有 path
error: opening file "/nix/store/...-source": No such file or directory
```

因为 nix-update 用 `nix flake metadata` 取 store 路径来做后续 eval，脏 git 树取不到 `path`。

**解法（已在本机验证有效）**：把工作树复制到一个**没有 `.git` 的临时目录**，在那里跑 `nix-update`（path flake 的 metadata 一定返回 `path`），改完再同步回工作树。

```bash
# 用工作树而不是 git archive HEAD：本地跑时未提交的改动也能参与升级
tar -C "$WS" -cf - --exclude=./.git --exclude=./wallpapers . | tar -x -C "$TMP"
cd "$TMP"
nix-update --flake tokens          # ✅ 成功：Update 27.1.1 -> 27.2.1
```

顺带避开 `wallpapers` submodule（1 GB 图包）：排除目录即可，且全仓库除 `checks/` 外没有引用它。

### 9.4 `scripts/auto-update.sh`（设计）

```bash
#!/usr/bin/env bash
# 在无 .git 的临时目录里做升级，构建通过才同步回工作树
set -uo pipefail
WS=${GITHUB_WORKSPACE:?}
TMP=$(mktemp -d)
LIST=".github/auto-update-packages.txt"     # 显式白名单，见 9.5

git -C "$WS" archive --format=tar HEAD | tar -x -C "$TMP"

CHANGED=0
while read -r spec; do
  [ -z "$spec" ] && continue
  pkg=${spec%%:*}; extra=${spec#*:}
  [ "$extra" = "$pkg" ] && extra=""

  before=$(cat "$TMP/packages/$pkg/default.nix")
  ( cd "$TMP" && nix-update --flake --quiet $extra "$pkg" ) || { echo "SKIP $pkg (update failed)"; continue; }
  after=$(cat "$TMP/packages/$pkg/default.nix")
  [ "$before" = "$after" ] && continue                      # 无版本变化

  if nix build --no-link ".#$pkg" 2>/dev/null; then          # 用 workdir 的 flake 构建
    echo "OK   $pkg"; cp "$after" "$WS/packages/$pkg/default.nix"; CHANGED=1
  else
    echo "FAIL $pkg (build failed, reverted)"                # 只回滚这一个包
    cp "$before" "$TMP/packages/$pkg/default.nix"
  fi
done < "$WS/$LIST"

git -C "$WS" rev-parse --verify HEAD >/dev/null
[ "$CHANGED" = 1 ] && ( cd "$WS" && nixfmt packages/*/default.nix ) || true
```

要点：

- **每个包独立 try/verify/rollback**：坏掉的包不影响其他包，这正是「高频自动更新」能长期跑下去的关键。
- 白名单进仓库（`.github/auto-update-packages.txt`），可 review、可停用单个包。
- 用 `nix-update --build` 在沙箱里先验证新版能编出来，编不出就不写回。

### 9.4.1 「假升级」守卫（实测发现的坑）

`nix-update` **只改 `version` 字段**，不会重写写在其它地方的字面版本号。第一次跑就撞上了：

```diff
- version = "27.1.1";
+ version = "27.2.1";
  url = "https://.../v27.1.1/tokens-v27.1.1-...tar.gz";   # ← 没变
  hash = "sha256-n8kpe...";                              # ← 也没变
```

结果：标签写 27.2.1，实际装的是 27.1.1 的二进制，而且构建**成功**（因为 hash 和 URL 仍然自洽）—— 这是最危险的一种。同类问题还有：

- `fetchFromGitHub` 的 `rev = "v0.1.16"`（字面 tag）
- `ldflags = [ "-X internal/version.Version=0.1.16" ]`（Go 包把版本编进二进制）

**两道防线**：

1. **包定义模板化**（一次性修正，已做）：

   ```nix
   let
     version = "0.1.16";
   in
   buildGoModule {
     pname = "herdr-plus";
     inherit version;
     src = fetchFromGitHub { rev = "v${version}"; ... };
     ldflags = [ "-X internal/version.Version=${version}" ];
   }
   ```

   已模板化：`tokens`、`opencode-zh-cn`、`ant-browser`（fetchurl URL）、`herdr-plus`（`rev` + ldflags）、`herdr-spreader`（`rev`）。

2. **脚本兜底守卫**（9.4 已实现）：升级后若旧版本字符串仍残留在文件里 → 判定升级不完整，回滚该包并报 `FAIL`。

   ```bash
   if [ -n "$old_ver" ] && [ "$old_ver" != "$new_ver" ] \
      && grep -qF "$old_ver" "$TMP/$file"; then
     echo "FAIL $pkg（旧版本仍残留，需改成 \${version} 模板）"
   fi
   ```

### 9.5 包白名单格式

```text
# 包名:额外的 nix-update 参数（可留空）
tokens
herdr-plus
herdr-sidebar
herdr-reviewr --use-github-releases
im-emoji-picker --version=branch
mihomo-meta --version=branch --version-regex '.*-(unstable-\d{4}-\d{2}-\d{2})'
aicommits
herdr-spreader
herdr-window-title-sync
herdr-worktrunk
```

### 9.6 lock 更新：保留人工确认的 `update-flake-lock.yml`

已定：**lock 更新不自动合并**。现有 workflow 已经是「每周一 `0 0 * * 1` 开 PR 到 `chore/update-flake-lock`」，保留即可，只补两点：

1. PR 创建后触发一次构建（或依赖 `build.yml` 的 PR 触发），让你在合并前就能看到 lock 是否破坏构建。
2. PR 描述里带上 `nix flake metadata --json` 的 input 版本 diff，方便判断风险。

想提高 lock 频率时只改 cron（例如 `0 0 * * *`），仍是人工合并。

lock 破坏构建时的排查手法（人工一次性）：逐 input 试，只保留能构建的：
```bash
for input in $(nix flake metadata --json | jq -r '.locks.nodes[].original | select(.type=="github") | .id' | sort -u); do
  cp flake.lock /tmp/lock.bak
  nix flake update "$input" || { cp /tmp/lock.bak flake.lock; continue; }
  nix build --no-link .#nixosConfigurations.nixos-desktop.config.system.build.toplevel \
    || cp /tmp/lock.bak flake.lock
done
```

代价是 eval 次数 × 60，只建议在人工排查时用。

### 9.7 workflow 骨架

> 仓库里的 `.github/workflows/auto-update.yml` 是权威实现（含沙箱升级、假升级守卫、Attic/Cachix 双推、PR 自动合并）。下面是结构示意，细节以文件为准。

`.github/workflows/auto-update.yml`

```yaml
name: Auto Update & Cache

on:
  schedule:
    - cron: "0 */12 * * *"    # 每 12 小时（UTC）
  workflow_dispatch:

# 本 workflow 只管 packages/* 的版本升级，不动 flake.lock。
# flake.lock 由 update-flake-lock.yml 每周开 PR、人工合并。

concurrency:
  group: auto-update
  cancel-in-progress: false    # 让上一轮跑完，避免半成品

permissions:
  contents: write
  pull-requests: write

env:
  ATTIC_SERVER: https://push.rhen.cloud   # 推送必走直连，CF 会 413
  ATTIC_CACHE: public

jobs:
  update:
    if: github.repository == 'RhenCloud/NixOS-Config'
    runs-on: ubuntu-latest
    timeout-minutes: 350
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: false            # 不拉 wallpapers
          fetch-depth: 0
          token: ${{ secrets.GITHUB_TOKEN }}

      - uses: DeterminateSystems/nix-installer-action@main
        with:
          extra-conf: |
            experimental-features = nix-command flakes
            substituters = https://cache.rhen.cloud https://cache.nixos.org https://nix-community.cachix.org https://hyprland.cachix.org https://niri.cachix.org https://noctalia.cachix.org https://vicinae.cachix.org
            trusted-public-keys = cache.rhen.cloud-1:... cache.nixos.org-1:... nix-community.cachix.org-1:... hyprland.cachix.org-1:... niri.cachix.org-1:... noctalia.cachix.org-1:... vicinae.cachix.org-1:...
            max-jobs = 4
            cores = 4
            keep-going = true

      - name: Bump self-packaged versions
        run: ./scripts/auto-update.sh

      - name: Commit to auto branch
        id: commit
        run: |
          set -euo pipefail
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git checkout -B auto/update
          git add -A
          if git diff --cached --quiet; then
            echo "changed=false" >> "$GITHUB_OUTPUT"; exit 0
          fi
          git commit -m "chore(auto): bump self-packaged package versions"
          git push -f origin auto/update
          echo "changed=true" >> "$GITHUB_OUTPUT"

      - name: Build all targets
        run: |
          set -euo pipefail
          nix build --no-link --print-out-paths \
            .#nixosConfigurations.nixos-desktop.config.system.build.toplevel \
            .#nixosConfigurations.yc-hk-1.config.system.build.toplevel \
            .#nixosConfigurations.nixos-homeserver.config.system.build.toplevel \
            | tee "$RUNNER_TEMP/paths.txt"

      - name: Push to Attic
        if: always() && hashFiles('${{ runner.temp }}/paths.txt') != ''
        env:
          ATTIC_TOKEN: ${{ secrets.ATTIC_PUSH_TOKEN }}
        run: |
          nix shell nixpkgs#attic-client -c bash -c '
            attic login rhen "$ATTIC_SERVER" "$ATTIC_TOKEN"
            attic push "rhen:$ATTIC_CACHE" $(cat "$RUNNER_TEMP/paths.txt")'

      - name: Open / update PR and auto-merge
        if: steps.commit.outputs.changed == 'true'
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          set -euo pipefail
          gh pr list --head auto/update --json number --jq '.[0].number' >/dev/null 2>&1 || true
          if ! gh pr view auto/update >/dev/null 2>&1; then
            gh pr create --base main --head auto/update \
              --title "chore(auto): bump self-packaged package versions" \
              --body "Automated version bumps for \`packages/*\`. All three host closures built successfully and were pushed to the binary cache. \`flake.lock\` is untouched." \
              --label dependencies
          fi
          # 三个主机闭包已在上一 step 全部构建成功 → 直接合并
          gh pr merge auto/update --squash --delete-branch
```

更保守的变体：用 `gh pr merge auto/update --squash --auto`，让 GitHub 等 `build.yml` 的 PR 检查通过再合并；代价是合并延后几分钟。二选一即可。

配合：`build.yml` 加 `if: github.event_name != 'pull_request' || github.head_ref != 'auto/update'`，避免自动分支上的重复构建。

### 9.8 防回路

- 自动提交只推到 `auto/update` 分支，`main` 由 PR 合并 → 天然不触发自己的 `push` 触发器。
- 合并后触发的 `publish-cache` / `build` 因为缓存已热，几乎是 no-op。
- 若改成就提交 `main`（省一次 PR），必须加 `paths-ignore` 或 `if: !contains(github.event.head_commit.message, 'chore(auto)')`。

### 9.9 安全性取舍（已定：包自动合并，lock 人工）

- **自动合并的前提是三个主机闭包全部构建成功**——比大多数人的「自动 merge dependabot」更强。
- 包版本升级失败会自动回滚，不会把仓库搞坏（每个包独立 verify/rollback）。
- `flake.lock` 永远走 `update-flake-lock.yml` 的人工 PR，nixpkgs 大变动不会被悄悄合进来。
- 临时停掉某个包的自动升级：从 `.github/auto-update-packages.txt` 删那一行即可。
- **提交信息与 PR 文案用英文**（仓库约定：代码注释中文，commit/PR 英文）。

---

## 10. 自有包自动化可行性实测

对全部 15 个候选包跑了完整一轮 `DRY_RUN=1 ./scripts/auto-update.sh`（沙箱工作树 + `--build`），
2026-11 结果：**7 升级、6 失败、2 无变化**。

| 包 | 实测结果 | 分类 |
| --- | --- | --- |
| `tokens` | ✅ `27.1.1 → 27.2.1`，且第二次跑 SAME（已最新） | 全自动 |
| `herdr-plus` | ✅ `0.1.16 → 0.1.24`（模板化 `rev`/ldflags 后） | 全自动 |
| `herdr-spreader` | ✅ `0.2.0 → 0.4.0`（模板化 `rev` 后） | 全自动 |
| `herdr-sidebar` | ✅ `0.7.0 → 0.16.0` | 全自动 |
| `herdr-reviewr` | ✅ `0.33.0 → 0.52.2` | 全自动 |
| `herdr-worktrunk` | ✅ `0.1.0 → 0.7.0` | 全自动 |
| `aicommits` | ✅ `4.1.1 → 5.0.1`（pnpm deps hash 也更新） | 全自动 |
| `im-emoji-picker` | ✅ `--version=branch` → `nightly-build-unstable-2026-01-03` | 需 `--version=branch` |
| `herdr-window-title-sync` | ✅ `--version=branch` → `0-unstable-2026-06-26`（上游无 tag） | 需 `--version=branch` |
| `opencode-zh-cn` | ✅ SAME（模板化后 8.7.0 已最新，无假升级） | 全自动 |
| `mihomo-meta` | ❌ 上游改动让编进二进制的 patch 失效（3 hunk 掉 1） | 需人工 rebase patch |
| `ant-browser` | ❌ 资产改名：`ant-browser-linux-amd64.zip` → `AntBrowser-1.9.x-linux-amd64.tar.gz` | 需人工改 fetch/unpack |
| `cloakbrowser` | ❌ 源站 `cloakbrowser.dev` 不是 nix-update 支持的 forge | 需 `--version` 手工或换成 GitHub 源 |
| `herdr-mobile-relay` | ❌ 升版本后构建失败（多产物/名称模板） | 待单独排查 |
| `zed-globalization` | ❌ 上游无 release（`releases/latest` 空），资产名无法推断 | 半自动/手工 |
| `cloudkeytao` | ❌ 直接引用 `inputs.cloudkeytao` | 由 lock 更新覆盖 |
| `ttt` / `ttt-herdr-plugin` | ❌ 引用 `inputs.ttt` | 由 lock 更新覆盖 |
| `deploy-rs` / `jailed-pi` | ❌ 引用 flake input | 由 lock 更新覆盖 |
| `bt-iso-enable` / `herdr-tab-rename` / `sandbox` | 本地源码（`Cargo.toml`/`src`/`Makefile`） | 手工 |

结论：**9 个包已实测全自动**（含 2 个 `--version=branch`），白名单就取这 9 个；
失败的 6 个都附带明确原因写进 `.github/auto-update-packages.txt` 的注释区，
需要时人工处理后再取消注释，避免每轮 CI 白跑。

---

## 11. 落地结构

```text
services/attic/                 # 服务器侧（Debian + Docker，不进 nix flake）
├── docker-compose.yml          # 只有 atticd（回环 8080）
├── server.toml
├── push.rhen.cloud.conf        # AcePanel 推送站点反代片段
├── atticd.env.example
├── install.sh                  # 幂等：建目录/生成密钥/起容器/备份 timer/自检
├── backup-db.sh + .service + .timer
└── README.md                   # runbook

scripts/
└── auto-update.sh              # 9.4

.github/
├── auto-update-packages.txt    # 9.5 白名单
└── workflows/
    ├── auto-update.yml         # 9.7（每 12 小时，包版本，自动合并）
    ├── update-flake-lock.yml   # 保留（每周开 PR，人工合并）
    └── publish-cache.yml       # 保留（push 触发），与 auto-update 共用缓存逻辑
```

仓库侧改动：

| 文件 | 改动 |
| --- | --- |
| `modules/_common/nix/nixos.nix` + `flake.nix` | 取消 `cache.rhen.cloud` 注释，填公钥 |
| `.github/workflows/publish-cache.yml` | 用 `attic push` 取代 `nixcache-oci`；改显式构建 toplevel |
| `.github/workflows/update-flake-lock.yml` | **保留**（lock 更新人工合并），只补构建触发与 input diff 描述 |
| `attic-push.sh` | 与 CI 对齐 |
| `secrets/hosts/hd-sg-1.yaml` | JWT secret 灾备副本 |
| `hosts/hd-sg-1/`、`deploy/default.nix`、`checks/deploy-nodes-schema`、`expected.hosts` | 单独提交移除（该机不装 NixOS） |

---

## 12. 分阶段实施

| 阶段 | 内容 | 状态 |
| --- | --- | --- |
| **P0** | S1–S5 前置检查 | ✅ 已测（Debian 13 / 4c5.8G / 99G；只能 root+YubiKey） |
| **P1** | `services/attic/` + `install.sh` | ✅ atticd 已跑；**待 CF 隧道路由**才能对外 |
| **P2** | 建 `public`（含上游 key）、CI token、公钥 | ✅ Priority 50、6 个上游 key、公钥 `public:fZV...` |
| **P3** | 客户端配置 + 单机验证 | ✅ 两处已填；循环内 push/narinfo/上游过滤均实测通过；待 HTTPS 后跑 `--from` |
| **P4** | `publish-cache.yml` 改造 + 手动跑一轮 | ⏳ 待 HTTPS |
| **P5** | `auto-update.sh` + 白名单 | ✅ 白名单 9 个已定（7 全自动 + 2 分支）；待首轮实推 |
| **P6** | `auto-update.yml` 接 PR + 自动合并 | ⏳ 待首轮 |
| **P7** | 稳定化：备份 timer、探活告警 | ⏳ |
| **P8** | 两周后决定退役 `nixcache-oci` | ⏳ |

### 前置检查

| 编号 | 内容 | 方式 |
| --- | --- | --- |
| S1 | SSH/Docker 可用（文档记录过 22222 无 banner） | `ssh -p 22222 rhencloud@81.31.208.183 'docker compose version'` |
| S2 | 磁盘余量 | `df -h /` |
| S3 | 80/443 可监听、DNS 已指 | `ss -lntp`、`dig +short cache.rhen.cloud` |
| S4 | SG↔国内带宽 | 桌面 `curl -o /dev/null -w '%{speed_download}' .../nar/<大文件>` |
| S5 | 一轮 auto-update 耗时 | 手动 `workflow_dispatch`，看日志 |

---

## 13. 运维与失败模式

- **GC**：atticd 内建 12h 一次，保留 30 天；磁盘 >80% 时 `attic cache configure --retention-period 14d public`。
- **备份**：每日 DB `.backup`，保留 14 份，rsync 到 `yc-hk-1`。
- **监控**：beszel-agent + 5 分钟探活 `curl -fsS .../nix-cache-info`。
- **升级 Attic**：先备份 DB（Attic 仍是 early prototype，升级等同 DB 迁移），回滚 = 旧 digest。

| 现象 | 影响 | 处置 |
| --- | --- | --- |
| `server.db` 丢 | 元数据 + 签名私钥丢失 | 恢复备份；否则重建缓存并更新所有客户端公钥 |
| 客户端公钥未配 | 缓存被当未签名，全回退编译 | 补 `extra-trusted-public-keys` |
| `api-endpoint` 错 | 推送 413 / 502 | `api-endpoint` 必须指向直连的 `https://push.rhen.cloud/`（CF 100 MB 上限） |
| lock 更新破坏构建 | 合并后本机编译失败 | lock PR 不自动合并（9.6）；人工逐 input 排查 |
| 包版本升级破坏构建 | 单个包坏 | 自动回滚该包（9.4），其余照常 |
| CI 每天全量重编 | 时间爆炸 | 确认 CI `substituters` 含自建缓存 |
| 自动 PR 与人工改动冲突 | PR 反复 rebase | `concurrency` + `-f` 推 `auto/update`；冲突时删分支重跑 |
| 证书续期失败 | 全站证书错 | 检查 80 端口（HTTP-01） |

---

## 14. 已定与剩余待确认

已定（用户确认）：

- **频率**：包更新**每 12 小时**；`flake.lock` 每周一次 PR、**人工合并**。
- **合并**：只对包更新自动合并（三个主机闭包全绿才合），lock 更新不自动合并。
- **档位**：**L 档**（三个主机 toplevel + `packages/*`）。
- **提交信息与 PR 文案**：英文。

仍待确认：

1. **白名单**：先开 §9.5 那 10 个，还是只开实测过的 4 个（`tokens`、`herdr-plus`、`herdr-sidebar`、`aicommits`）？
2. **首轮实施顺序**：先落地 `services/attic/`（P1–P4），还是先把 `auto-update.yml` 跑起来（构建结果先推现有 Cachix，等 Attic 上线再换 push 目标）？
3. 是否单独一次提交清理 `hosts/hd-sg-1/` 与 `deploy` 里的死节点？