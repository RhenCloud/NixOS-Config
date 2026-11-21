# hd-sg-1 自建 Nix 二进制缓存 设计方案

> 状态：设计稿（v2），未落地。
> 目标主机：`hd-sg-1`（Hostinger 新加坡，`81.31.208.183`）——**保留 Ubuntu，不重装 NixOS**。
> 域名：`https://cache.rhen.cloud`。
> v2 变更：改为 Ubuntu + Docker 部署；新增「只缓存上游没有的路径」的空间模型与实测数据。

## 1. 目标与非目标

目标：

- 在 `hd-sg-1`（Ubuntu）上跑一个**可写**的 Nix 二进制缓存，域名 `https://cache.rhen.cloud`。
- 只缓存**上游拿不到的路径**（自己打的包、patch 过的包、flake 里自建的包），公共依赖继续走 `cache.nixos.org` / USTC / SJTU / 各家 cachix。
- CI 与本机能推，所有主机能匿名拉。
- 服务器侧虽然不能声明式管理，但**配置、密钥、备份、升级步骤全部进仓库**，做到「换台机器照着 runbook 十分钟重建」。
- 复用现有设施：Docker（AB 已经在用）、Cloudflare DNS、beszel 监控。

非目标：

- 不做多租户、不对外开写权限（单个 `public` 缓存，匿名只读）。
- 不替代 `cache.nixos.org` 或镜像（优先级排在它们之后）。
- 不缓存 NixOS ISO / 全量 nixpkgs。
- 不追求双活/高可用（单实例 + 每日数据库备份）。

## 2. 现状与约束

| 事实 | 影响 |
| --- | --- |
| `hd-sg-1` **只能跑 Ubuntu**，AutoBangumi 用 docker compose 手工部署 | 放弃 `hosts/hd-sg-1` 的 NixOS 路线；`modules/server/attic` 这类 NixOS 模块**不再需要**，改为仓库里的 compose + 脚本 + runbook |
| 该机已装 Docker + compose | 直接复用，不引入新运行时 |
| `hd-sg-1` 无法被 sops-nix 解密、无法 deploy-rs | 密钥在服务器本地生成并落盘；**同时在仓库 `secrets/hosts/hd-sg-1.yaml` 留一份加密副本用于灾备**（Ubuntu 不需要解密，但你需要能找回它） |
| `flake.nix` 与 `modules/_common/nix/nixos.nix` 里 `cache.rhen.cloud` 全是注释 | 客户端接入只是「取消注释 + 填公钥」 |
| `attic-push.sh` 已按 Attic 写好（`https://cache.rhen.cloud` / 缓存名 `public`） | 选型与脚本预期一致 |
| 已有 `nixcache-oci`（GHCR）+ 本地 `nixcache-proxy` | 并存观察，验证后再决定退役 |
| 磁盘是单盘（Ubuntu 大概率 ext4，无 btrfs qgroup 限额可用） | 靠 attic 的保留期 + GC + 水位告警控制，而不是文件系统配额 |

## 3. 空间模型：到底要存多少（这是本方案的核心）

### 3.1 上游过滤是默认行为，不用自己实现

`attic push` 自带 **upstream cache filter**：推送时检查本地 store path 的签名，凡是带 `cache.nixos.org-1`、`nix-community.cachix.org-1` 等已登记上游 key 的路径直接跳过。所以「只存上游没有的」不是需要额外开发的功能，**是默认结果**，前提是把所有在用的上游 key 都登记进去。

### 3.2 实测：`nixos-desktop` 当前系统闭包

| 分类 | 路径数 | NAR 大小 | 占比 |
| --- | --- | --- | --- |
| 上游已签名（自动跳过） | 3246 | 39.82 GiB | 78.3% |
| **无任何签名（会被推送）** | **1018** | **11.03 GiB** | **21.7%** |
| 合计 | 4264 | 50.85 GiB | 100% |

再对那 1018 个路径逐个查 `cache.nixos.org` / `nix-community.cachix.org` 的 narinfo：

- 236 个（23%）其实上游有（本地重编但产物相同），**但只占 0.21 GiB（2%）**；
- 782 个（77%）是真的本地独有，占 **10.81 GiB（98%）**。

**结论：预查 narinfo 只能再省 2%，不值得写复杂脚本；真正的空间杠杆是「推哪些包」，不是「过滤得再细」。**

### 3.3 那 11 GiB 到底是谁

| 包 | NAR |
| --- | --- |
| wpsoffice-cn | 2.02 GiB |
| feishu | 1.67 GiB |
| vscode | 0.99 GiB |
| nvidia-x11（含 lib32/firmware/kernel-modules） | 1.29 GiB |
| ant-browser | 0.82 GiB |
| wechat | 0.70 GiB |
| qq | 0.60 GiB |
| google-chrome | 0.44 GiB |
| zedg | 0.41 GiB |
| zen-beta-bin | 0.40 GiB |
| slack | 0.33 GiB |
| niri-unstable / source / 其他小包 | ≈ 1.36 GiB |

即：**约 9.2 GiB 是「桌面专用的大型闭源/patched 应用」，1.8 GiB 才是基础设施相关的自建包**（niri、mihomo-meta、herdr、piri、sddm-astronaut、nixvim、rime 词库等）。

### 3.4 三档推送策略（选一档，可随时切换）

| 档 | 推送范围 | 未压缩 | zstd 落盘（估） | 适用 |
| --- | --- | --- | --- | --- |
| **S（推荐）** | 服务器主机闭包 + `packages/*` + flake 自建包 | ≈ 1.8 GiB | **≈ 0.7 GiB** | 只服务「多机共享 / CI 复用 / 重装免编译」，不缓存桌面 GUI 大包 |
| M | S + 桌面闭包里的非 GUI 部分 | ≈ 4 GiB | ≈ 1.6 GiB | 想加速桌面回滚 |
| L | 桌面全闭包（默认 `attic push` 行为） | 11.03 GiB | **≈ 4.5 GiB** | 想「重装系统零编译」，含 wps/feishu/chrome 等 |

**建议 S**：桌面那 9 GiB 闭源大包在别的机器上基本用不到（`yc-hk-1`/`homeserver` 是服务器），而它们版本一变就全量重传、分块去重几乎无效（二进制大文件）。真需要「重装零编译」时，临时切 L 推一次，推完把保留期调短让它自然 GC 掉。

保留期 30 天 + attic 内建 GC，S 档稳态 **< 1.5 GiB**，L 档稳态 **5–8 GiB**。空间完全不是问题——**真正要克制的是 SG 出口带宽**（见 §8）。

## 4. 方案选型

| 方案 | 可写 | 服务端签名 | 去重/压缩 | 认证 | 结论 |
| --- | --- | --- | --- | --- | --- |
| **Attic**（`ghcr.io/zhaofengli/attic`） | ✅ | ✅ 推送方拿不到私钥 | ✅ CDC 分块 + zstd + 全局去重 + GC | ✅ JWT，按缓存/权限签发 | **选它** |
| Harmonia | ❌ 只读 | ✅ | ❌ | ❌ | 需要额外共享 store |
| nix-serve | ❌ 只读 | ❌ | ❌ | ❌ | 太原始 |
| nixcache-oci（现有） | ✅ 但仅 CI | ✅ | ✅ | GHCR token | 保留为过渡 |
| Cachix | ✅ | ✅ | ✅ | 托管 | 私有缓存付费 |

官方镜像 `ghcr.io/zhaofengli/attic`，启动方式 `atticd -f /attic/server.toml --mode monolithic`（API + GC 同进程，SQLite + 本地存储）。

## 5. 拓扑

```text
  ┌────────────────┐  attic push (JWT)   ┌──────────────────────────────────┐
  │ GitHub Actions │ ──────────────────▶ │ hd-sg-1 (Ubuntu, 81.31.208.183)  │
  └────────────────┘                     │                                  │
  ┌────────────────┐  attic push (JWT)   │  caddy:2  ── 443/80 ──▶ 8080     │
  │ nixos-desktop  │ ──────────────────▶ │     ▲                            │
  │ (本地构建)      │                     │     │ 127.0.0.1:8080             │
  └───────┬────────┘                     │  attic (ghcr.io/zhaofengli/attic)│
          │ 匿名 GET (无 token)           │   ├ /srv/atticd/server.toml      │
          │ /nix-cache-info               │   ├ /srv/atticd/data/server.db   │
          │ /<hash>.narinfo               │   └ /srv/atticd/storage/         │
          │ /nar/<...>                    └──────────────────────────────────┘
          │                                        ▲
  ┌───────▼────────┐  匿名 GET                    │
  │ yc-hk-1        │ ─────────────────────────────┘
  │ nixos-homeserver│
  └────────────────┘
```

公网只暴露 443/80 给 Caddy；atticd 只监听 `127.0.0.1:8080`。

## 6. 关键设计决策

### D1 运行时：Docker Compose，镜像按 digest 锁定

```yaml
# services/attic/docker-compose.yml
services:
  atticd:
    image: ghcr.io/zhaofengli/attic:latest   # 落地时改成 @sha256:<digest>
    container_name: atticd
    command: ["-f", "/attic/server.toml", "--mode", "monolithic"]
    restart: unless-stopped
    env_file: [./atticd.env]                 # ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64
    volumes:
      - ./server.toml:/attic/server.toml:ro
      - /srv/atticd/data:/attic/data
      - /srv/atticd/storage:/attic/storage
    ports: ["127.0.0.1:8080:8080"]
    logging: { driver: json-file, options: { max-size: "20m", max-file: "5" } }

  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    network_mode: host                     # 直接占 80/443，避免端口映射层
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - /srv/atticd/caddy:/data
```

- 不用 `nix profile` 在 Ubuntu 上装 atticd：Docker 已是该机既有依赖，镜像自带依赖，升级只需改 digest。
- `latest` 只是初稿；落地时 `docker inspect --format '{{index .RepoDigests 0}}'` 取 digest 写回 compose，避免半夜被上游破坏性升级打中。
- 容器以什么用户跑要先确认（`docker run --rm --entrypoint id <image>`）；若不是 root，`/srv/atticd/{data,storage}` 要 `chown` 成对应 uid。

### D2 配置 `server.toml`

```toml
listen = "0.0.0.0:8080"          # 容器内监听，宿主机只映射到 127.0.0.1
allowed-hosts = ["cache.rhen.cloud"]
api-endpoint = "https://cache.rhen.cloud/"   # 结尾必须有 /

[database]
url = "sqlite:///attic/data/server.db?mode=rwc"

[storage]
type = "local"
path = "/attic/storage"

[compression]
type = "zstd"
level = 19                        # 写入量小，宁可多花 CPU 换更小的落盘

[chunking]
nar-size-threshold = 65536
min-size = 16384
avg-size = 65536
max-size = 262144

[garbage-collection]
interval = "12 hours"
default-retention-period = "30 days"
```

- `api-endpoint` 决定 narinfo 里返回的 NAR URL，写错客户端会 404，这是最常见的坑。
- `level = 19` 比默认 8 大约再省 15% 空间，推送量小所以 CPU 不是瓶颈；若推送变慢可回落到 12。
- **不要**给 `/nar/*` 套 Caddy 的 `encode`（NAR 本身已是 zstd，二次压缩纯浪费 CPU）。

### D3 TLS：Caddy + HTTP-01（灰云）

`Caddyfile`：

```caddyfile
cache.rhen.cloud {
    reverse_proxy 127.0.0.1:8080 {
        flush_interval -1     # 大 NAR 流式传输，别攒缓冲
    }
    header {
        Strict-Transport-Security "max-age=31536000"
        -Server
    }
    log {
        output file /data/access.log {
            roll_size 50mb
            roll_keep 3
        }
        format console
    }
}
```

- DNS：`cache.rhen.cloud` A → `81.31.208.183`，**灰云（DNS only）**。Caddy 用 HTTP-01 自动签 Let's Encrypt 证书，不需要 Cloudflare API token（比 `yc-hk-1` 的 DNS-01 方案少一个密钥依赖）。
- 需要放行 80/443：Hostinger 面板无端口封锁，只需 `ufw allow 80,443/tcp`（若启用了 ufw）。
- 备选：Cloudflare Tunnel（`cloudflared`）——不开任何端口、不用证书，但所有流量经 CF 代理，二进制大文件有 ToS 与限速风险，**不推荐做主路径**，仅在机器拿不到公网 80/443 时启用。
- 橙云 + 缓存 `/nar/*`（内容寻址、不可变）能显著改善国内访问并省 SG 出口，但同样受 CF 对非 HTML 内容的策略限制，列为 P5 可选优化。

### D4 客户端接入：匿名读 + 公钥信任

只改仓库两处（必须同步，否则 flake 的 `nixConfig` 会覆盖模块设置）：

```nix
substituters = [ ... "https://cache.rhen.cloud" ];
trusted-substituters = [ ... "https://cache.rhen.cloud" ];
extra-trusted-public-keys = [ ... "cache.rhen.cloud-1:<attic cache info 输出的公钥>" ];
```

- 公钥由 atticd 在 `attic cache create` 时生成并存进 `server.db`，用 `attic cache info public` 查。
- 必须写 `extra-trusted-public-keys`（仓库里已踩过 `trusted-public-keys` 被覆盖的坑）。
- **缓存优先级设 50**（`cache.nixos.org` 是 40，越小越优先）：公共包继续命中镜像，只有私有路径才落到 SG。等 §11 的带宽实测出来再决定是否提到 30。

### D5 推送策略：S 档（只推基础设施相关路径）

`attic-push.sh` 改成三档，默认 S：

```bash
# S 档：服务器闭包 + 仓库自定义包
attic push public \
  $(nix build .#nixosConfigurations.yc-hk-1.config.system.build.toplevel --print-out-paths) \
  $(nix build .#nixosConfigurations.nixos-homeserver.config.system.build.toplevel --print-out-paths) \
  $(nix build .#packages.x86_64-linux.default --print-out-paths)

# L 档：桌面全闭包（含 wps/feishu/chrome 等大包），用完把保留期调短
attic push public $(nix build .#nixosConfigurations.nixos-desktop.config.system.build.toplevel --print-out-paths)
```

`attic push` 默认走闭包 + 上游过滤，所以 S 档推的是「服务器闭包里上游没有的那些」——实测桌面是 11 GiB，服务器闭包没有 GUI 大包，预计 **1–2 GiB**。

`attic cache create` 时把所有在用的上游 key 登记进去，否则上游过滤形同虚设：

```bash
attic cache create --public public \
  --upstream-cache-key-name cache.nixos.org-1 \
  --upstream-cache-key-name nix-community.cachix.org-1 \
  --upstream-cache-key-name hyprland.cachix.org-1 \
  --upstream-cache-key-name niri.cachix.org-1 \
  --upstream-cache-key-name noctalia.cachix.org-1 \
  --upstream-cache-key-name vicinae.cachix.org-1
```

> 可选再省 2%：推送前对每个 path 查 `cache.nixos.org/<hash>.narinfo`，200 就跳过（现有 `attic-push.sh` 已有这段逻辑，可保留）。实测只省 0.21 GiB，收益有限，别为它增加串行 HTTP 请求。

### D6 三条推送管道

1. **CI**（`publish-cache.yml`）：S 档，构建后 `attic push public <toplevel...>`。token 走 GitHub Secret `ATTIC_PUSH_TOKEN`。
2. **桌面/开发机**：默认**不开** `watch-store`（会把 9 GiB GUI 大包自动推上去）。需要时手工 `attic push`。
3. **手工**：`attic-push.sh` 的 S/L 两档。

### D7 与 nixcache-oci 的关系：并存 → 观察 → 退役

两者并存：Attic 优先、GHCR 兜底。等验证全过、桌面连续两周 `nix build` 命中正常后，再删 `nixcache` input 与 `services.nixcache-proxy`（独立提交，可回滚）。

### D8 密钥与令牌（Ubuntu 上没有 sops）

| 名称 | 服务器位置 | 仓库副本 | 用途 |
| --- | --- | --- | --- |
| RS256 JWT secret | `/srv/atticd/atticd.env`（root:root 0400） | `secrets/hosts/hd-sg-1.yaml` 加密存一份 | atticd 签/验 token |
| 缓存签名私钥 | **`server.db` 内**（`attic cache create` 生成） | 每日 DB 备份 | 服务端签名 NAR |
| `ATTIC_PUSH_TOKEN`（CI） | GitHub Secrets | — | `--pull '*' --push 'public'`，有效期 2 年 |
| 桌面推送 token | 桌面 `~/.config/attic/config.toml`（可 sops 渲染） | `secrets/hosts/nixos-desktop.yaml` | 手工推送 |

生成 JWT secret（Ubuntu 上直接 openssl）：

```bash
openssl rand -base64 64 | tr -d '\n' > /srv/atticd/atticd.env.tmp
printf 'ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=%s\n' "$(cat /srv/atticd/atticd.env.tmp)" > /srv/atticd/atticd.env
chmod 600 /srv/atticd/atticd.env && shred -u /srv/atticd/atticd.env.tmp
```

签发 token（容器内执行）：

```bash
docker compose exec atticd atticadm make-token --sub ci --validity 2y --pull '*' --push 'public'
```

**签名私钥在 `server.db` 里**——NAR 丢了能重推，私钥丢了所有客户端都得改公钥。所以 DB 备份是唯一必做的备份项。

## 7. 落地结构

### 7.1 服务器侧（仓库新增目录）

```text
services/attic/
├── docker-compose.yml
├── server.toml
├── Caddyfile
├── install.sh            # 幂等：建目录/生成密钥/起容器/开防火墙
├── backup-db.sh          # sqlite3 .backup + 保留 14 份 + rsync 到 yc-hk-1
├── backup-db.service
├── backup-db.timer
└── README.md             # runbook：首装、升级、恢复、GC、故障排查
```

`install.sh` 要点：

- 检查 docker / compose 存在、80/443 未被占用；
- 创建 `/srv/atticd/{data,storage,caddy}`，`chown` 成镜像运行用户；
- 已存在 `atticd.env` 时**不覆盖**（幂等）；
- `docker compose up -d`，然后 `curl -fsS https://cache.rhen.cloud/nix-cache-info` 自检。

### 7.2 仓库侧（Nix）

| 文件 | 改动 |
| --- | --- |
| `modules/_common/nix/nixos.nix` | 取消 `https://cache.rhen.cloud` 注释；填公钥 |
| `flake.nix` | `nixConfig.substituters` / `trusted-substituters` / `extra-trusted-public-keys` 同步 |
| `.github/workflows/publish-cache.yml` | 增加 Attic 推送步骤（保留 GHCR 步骤） |
| `attic-push.sh` | 改成 S/L 两档，默认 S |
| `secrets/hosts/hd-sg-1.yaml` | 存 JWT secret 的灾备副本 |
| `secrets/hosts/nixos-desktop.yaml` | 桌面推送 token |
| `docs/nix-cache-design.md` | 本文 |

> `hosts/hd-sg-1/`、`deploy/default.nix` 里的 `hd-sg-1` 节点、`checks/deploy-nodes-schema` 的期望列表：既然该机不装 NixOS，这些是死配置。建议**单独一次提交**把它们移除（同时改 `expected.hosts`），避免以后有人误以为能 `deploy`。本次方案不改。

## 8. 流量模型（比磁盘更需要克制）

| 方向 | 场景 | 估算 |
| --- | --- | --- |
| 入站 | 首次 S 档推送 | 1–2 GiB |
| 入站 | 日常增量（分块去重后） | 0.1–0.5 GiB/次 |
| 入站 | 一次性 L 档（桌面全闭包） | 11 GiB |
| 出站 | `yc-hk-1`/`homeserver` 跟随更新 | 0.5–3 GiB/月 |
| 出站 | 新机/重装全量 | 1–2 GiB（S）/ 11 GiB（L） |

结论：S 档稳态 **出站 3–5 GiB/月**，远低于 Hostinger 配额。L 档偶发会顶到 10 GiB+，所以不建议常开。

## 9. 运维

- **GC**：atticd 内建，12 小时一次，保留期 30 天。磁盘水位超 80% 时把 `default-retention-period` 降到 14 天并重启容器（`attic cache configure --retention-period 14d public` 亦可）。
- **备份**：`backup-db.timer` 每日 `sqlite3 /srv/atticd/data/server.db ".backup /srv/atticd/backup/server-$(date +%F).db"`，保留 14 份，`rsync -e 'ssh -p 22222'` 到 `yc-hk-1:/var/backups/atticd/`。**只备份 DB**。
- **监控**：`beszel-agent` 容器上报 CPU/内存/磁盘；另加 5 分钟 timer 探活 `curl -fsS https://cache.rhen.cloud/nix-cache-info`，失败写 syslog（如需邮件告警，复用 `yc-hk-1` 上的 mailer 做远端探测更简单）。
- **升级**：`docker compose pull` → 看 changelog（Attic 仍是 early prototype，**升级等同数据库迁移**）→ 先跑一次 `backup-db.sh` → `docker compose up -d`。回滚 = 改回旧 digest。
- **常用命令**：

```bash
cd /srv/atticd
docker compose logs -f atticd --tail 100
docker compose exec atticd atticadm make-token --sub ci --validity 2y --pull '*' --push 'public'
curl -fsS https://cache.rhen.cloud/nix-cache-info
attic cache info public            # 客户端执行，看公钥/优先级/保留期
du -sh /srv/atticd/storage /srv/atticd/data
```

## 10. 分阶段落地

| 阶段 | 内容 | 验证 |
| --- | --- | --- |
| **P0** | §11 的 S1–S4（SSH/root、Docker、端口、磁盘、带宽） | 全通过才继续 |
| **P1** | `services/attic/` 目录 + `install.sh`，容器起来 | `curl -fsS https://cache.rhen.cloud/nix-cache-info` 返回 `StoreDir: /nix/store` |
| **P2** | 建 `public` 缓存（含上游 key）、签发 token、取公钥 | `attic cache info public` 有公钥与 `Priority: 50` |
| **P3** | 客户端配置（`modules/_common/nix` + `flake.nix`），单机验证 | `nix copy --from https://cache.rhen.cloud <自建包>` 成功，且 `nix build` 不报警告 |
| **P4** | CI S 档推送 + 观察磁盘/流量两周 | CI 日志有 pushed/skipped 统计；`du -sh` 符合 §3.4 |
| **P5** | 备份 timer、beszel、探活告警；评估橙云缓存 `/nar/*` | 备份可还原（在测试目录 restore 一次） |
| **P6** | 观察两周后决定退役 `nixcache-oci` | 独立提交，可回滚 |

## 11. 落地前必须验证

| 编号 | 内容 | 方式 | 失败时 |
| --- | --- | --- | --- |
| **S1** | SSH 可达 + root/sudo + Docker 可用（文档记录过 22222 无 banner） | `ssh -p 22222 rhencloud@81.31.208.183 'docker compose version'` | 先解决可达性，否则整案无法启动 |
| **S2** | 磁盘余量与 ext4 是否可扩 | `df -h /`、`lsblk` | < 20 GiB 可用 → 保留期 14 天 + S 档 |
| **S3** | 80/443 是否可对外监听、DNS 是否已指向该机 | `ss -lntp \| grep -E ':(80\|443)'`、`dig +short cache.rhen.cloud` | 端口被占 → 换 Caddy 端口；DNS 未生效 → 先改 A 记录 |
| **S4** | SG ↔ 国内实际带宽（决定优先级 50 是否合适） | 桌面 `curl -o /dev/null -w '%{speed_download}' https://cache.rhen.cloud/nar/<大文件>` | < 1 MB/s → 保持优先级 50，评估橙云缓存 |

## 12. 失败模式

| 现象 | 影响 | 检测 | 处置 |
| --- | --- | --- | --- |
| 磁盘写满 | atticd 写失败，AB/sshd 也受影响 | 水位告警 | 降保留期 + `attic cache configure` + 手工 GC |
| `server.db` 损坏/丢失 | 元数据 + **签名私钥**丢失 | 服务起不来 / narinfo 404 | 恢复每日备份；无备份则重新 `attic cache create` 并更新所有客户端公钥 |
| 客户端公钥未配 | 本缓存被当作未签名，全部回退源码构建 | `nix build -vv` 显示签名不匹配 | 补 `extra-trusted-public-keys` |
| `api-endpoint` 写错 | narinfo 里的 NAR URL 指向错误域名，拉取 404 | 手工 `curl` narinfo 看 URL | 改成 `https://cache.rhen.cloud/` 后重启 |
| 证书续期失败 | 全站证书错误 | 探活失败 | 检查 80 端口是否放行（HTTP-01 依赖） |
| 镜像 `latest` 破坏性升级 | 容器起不来 | `docker compose logs` | 回滚到旧 digest + 恢复 DB 备份 |
| CI token 过期 | 推送 401 | CI 日志 | 重新签发并更新 Secret |

## 13. 待确认

1. **推送档位**：默认 **S（≈0.7 GiB 落盘）**，还是直接 L（≈4.5 GiB，重装零编译）？
2. **桌面是否开 `watch-store` 自动推送**？开了就会把 wps/feishu 这类大包也推上去（等价 L 档）。
3. **是否清理 `hosts/hd-sg-1/` 与 `deploy` 里的死节点**（既然不装 NixOS）？
4. **`nixcache-oci`** 并存观察还是直接替换？
