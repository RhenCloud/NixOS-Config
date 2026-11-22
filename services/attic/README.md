# Attic 二进制缓存（cache.rhen.cloud）

自建 Nix 二进制缓存，只存**上游没有的**路径（自建包 / patch 过的包）。
公共依赖继续走 `cache.nixos.org` 与各家 cachix，靠客户端 Priority 控制（本缓存 50 > 上游 40）。

| 项 | 值 |
| --- | --- |
| 主机 | `hd-sg-1`（`81.31.208.183`，Hostinger 新加坡，Debian 13 trixie） |
| 域名 | 下载 `https://cache.rhen.cloud` · 推送 `https://push.rhen.cloud` |
| 入口 | 下载：**Cloudflare Tunnel**（token 模式 cloudflared，路由在 CF 面板）；推送：**灰云 A + AcePanel nginx** |
| 证书 | 下载：CF 边缘自动签；推送：AcePanel 通配符 `*.rhen.cloud`（cert_id=1，面板自动续期） |
| 服务端 | `atticd --mode monolithic`，SQLite 单文件 + 本地存储，单容器约 83 MiB |
| 数据 | `/srv/atticd/{data,storage,backups}` |

设计与容量模型见 [`docs/nix-cache-design.md`](../../docs/nix-cache-design.md)。

## 拓扑

```text
                     ┌─ 下载：cache.rhen.cloud（橙云）
nix / attic pull ────┤   CF 边缘 TLS ──tunnel──▶ cloudflared ─┐
                     │                                        ├──http──▶ atticd 127.0.0.1:8080
                     └─ 推送：push.rhen.cloud（灰云 A）         │              ├── /srv/atticd/data/server.db
                        AcePanel nginx（*.rhen.cloud 证书）─────┘              ├── /srv/atticd/storage
                                                                               └── /srv/atticd/backups
```

**为什么必须两个入口**：`attic push` 把整个 NAR 当成**一个 PUT 请求体**上传（服务端再分块去重），
而 Cloudflare 免费版单请求上限 100 MB（Pro 也只 500 MB），GB 级包必被 413。
实测：直连 PUT 95 MB 通过、120 MB → `413 Payload Too Large`（cloudflare）。下载没有这个限制。
服务端用 `api-endpoint`（推送，指直连域）/ `substituter-endpoint`（拉取，指 CF 域）两项分开下发；
客户端一旦在 cache-config 里看到 `api-endpoint` 就会把上传端点改写成它，所以推送端必须写直连域。

## 目录结构

```text
services/attic/
├── docker-compose.yml          # 只有 atticd（回环 8080）
├── server.toml                 # atticd 配置
├── push.rhen.cloud.conf        # 推送入口：AcePanel nginx 反代（client_max_body_size 0）
├── atticd.env.example          # RS256 JWT 私钥模板（真实文件不提交）
├── install.sh                  # 幂等安装：依赖/目录/私钥/校验/启动/备份 timer
├── backup-db.sh                # 每日 sqlite3 .backup（在线备份）
├── atticd-backup.service       # 调用 /usr/local/bin/atticd-backup
└── atticd-backup.timer         # 每日 04:17（带随机延迟）
```

## 首次部署

### 1. 装服务端本体

```bash
git clone https://github.com/RhenCloud/NixOS-Config /opt/NixOS-Config
/opt/NixOS-Config/services/attic/install.sh
curl -fsS http://127.0.0.1:8080/nix-cache-info    # 应返回 StoreDir / WantMassQuery / Priority
```

`install.sh` 会：装 docker/compose/sqlite3 → 建 `/srv/atticd/*` → 生成 `atticd.env`
（若不存在）→ `check-config` → 启动容器 → 装备份 timer → 本机自检。

**生成私钥后立刻把 `atticd.env` 加密备份到 `secrets/hosts/hd-sg-1.yaml`**

```bash
# 已落地：键名为 attic-token-rs256-secret-base64（base64 原文，无换行）
sops set secrets/hosts/hd-sg-1.yaml '["attic-token-rs256-secret-base64"]' \
  --value-stdin <<< "\"$(cut -d= -f2- /opt/attic/atticd.env | tr -d '\n')\""
```

（`sops set` 的值需要 JSON 字符串，所以套一层引号；`--value-stdin` 避免密钥出现在 `ps` 里。）

私钥丢了 = 所有客户端令牌立即失效，必须重新分发。

### 2. 对外入口（两个）

#### 下载侧（CF 面板，一次性）

1. **DNS → Records**：删掉 `cache` 的旧 A 记录（不能与自动建的 CNAME 冲突）。
2. **Zero Trust → Networks → Tunnels** → 选中本机那条（HEALTHY）→ `⋯` → Configure →
   **Public Hostname** → Add a public hostname：
   - Subdomain `cache`、Domain `rhen.cloud`、Path 留空
   - Service Type `HTTP`、URL `127.0.0.1:8080`

保存后 CF 自动生成 `cache.rhen.cloud` 的 CNAME（橙云）并签发边缘证书。

```bash
curl -fsS https://cache.rhen.cloud/public/nix-cache-info
```

#### 推送侧（已执行，脚本化）

> **入口已从 1Panel OpenResty 迁到 AcePanel**：80/443 现由 `/opt/ace/server/nginx` 接管，
> 站点配置按 AcePanel 布局放在 `/opt/ace/sites/<域名>/config/site.conf`，
> 且必须在 `/opt/ace/panel/storage/panel.db` 的 `websites` 表登记，否则站点能跑但不出现在面板里。

1. DNS：`push` A 记录 → `81.31.208.183`，**灰云**（不走 CF 代理）。
2. 建目录并放配置：

```bash
SITE=/opt/ace/sites/push.rhen.cloud
mkdir -p "$SITE"/{config,ssl,public,log}
cp services/attic/push.rhen.cloud.conf "$SITE/config/site.conf"

# 复用 cert_id=1 的通配符 *.rhen.cloud（与 git/list/status 同一张）
cp /opt/ace/sites/git.rhen.cloud/ssl/fullchain.pem "$SITE/ssl/fullchain.pem"
cp /opt/ace/sites/git.rhen.cloud/ssl/privkey.pem   "$SITE/ssl/privkey.pem"
chmod 644 "$SITE/ssl/fullchain.pem"
chmod 600 "$SITE/ssl/privkey.pem"
```

3. 在 AcePanel 数据库登记站点（**必做**，否则面板看不到这个站）：

```bash
cp /opt/ace/panel/storage/panel.db /root/panel.db.bak-$(date +%Y%m%d%H%M%S)
sqlite3 /opt/ace/panel/storage/panel.db <<'SQL'
INSERT INTO websites (name, type, status, path, ssl, cert_id, project_id, remark, created_at, updated_at)
VALUES ('push-rhen-cloud', 'proxy', 1, '/opt/ace/sites/push.rhen.cloud/public', 1, 1, 0,
        'attic 推送入口（直连，绕开 Cloudflare 100MB 单请求上限）',
        datetime('now'), datetime('now'));
SQL
```

4. 校验并重载：

```bash
/opt/ace/server/nginx/sbin/nginx -t && /opt/ace/server/nginx/sbin/nginx -s reload
curl -sS --noproxy '*' https://push.rhen.cloud/public/nix-cache-info
```

证书续期：沿用 `cert_id=1` 的 AcePanel 自动续期（通配符 `*.rhen.cloud`，
无需单独的 acme.sh 条目；旧的 `acme.sh-renew.timer` 已随 1Panel 一起退役）。

关键指令：`client_max_body_size 0`（默认 50m，不放开推 NAR 直接 413）、
`proxy_request_buffering off`、`proxy_buffering off`、超时 3600s、`proxy_set_header Host $host`
（atticd 的 `allowed-hosts` 要校验这个）。

### 3. 一次性初始化

```bash
cd /opt/NixOS-Config/services/attic

# CI 令牌（2 年有效，pull 任意 / push 仅 public） -> GitHub secret ATTIC_PUSH_TOKEN
docker compose exec atticd atticadm -f /attic/server.toml make-token \
  --sub ci --validity 2y --pull '*' --push 'public'

# 在任一装了 attic-client 的机器上（先 attic login rhen https://push.rhen.cloud <token>）
attic cache create --public --priority 50 public \
  --upstream-cache-key-name cache.nixos.org-1 \
  --upstream-cache-key-name nix-community.cachix.org-1 \
  --upstream-cache-key-name hyprland.cachix.org-1 \
  --upstream-cache-key-name niri.cachix.org-1 \
  --upstream-cache-key-name noctalia.cachix.org-1 \
  --upstream-cache-key-name vicinae.cachix.org-1

attic cache info public      # 记下公钥，填进 flake.nix
```

`Priority` 设 **50**（高于 `cache.nixos.org` 的 40），让本地独有路径优先命中本缓存。

注意：`atticadm` **必须带 `-f /attic/server.toml`**，否则报 `No such file or directory`；
建缓存用的令牌必须带 `--create-cache '*'`，只给 `--pull/--push` 会报 `AccessError`。

## 客户端接入

`flake.nix` 与 `modules/_common/nix/nixos.nix` 两处同步：

```nix
substituters = [ "https://cache.rhen.cloud/public" ];
trusted-substituters = [ "https://cache.rhen.cloud/public" ];
extra-trusted-public-keys = [ "public:<公钥>" ];
```

两个坑：**substituter URL 必须带缓存名 `/public`**（裸域名一直 401）；
**公钥名是缓存名而不是域名**（`public:fZVnkMmYL+VX7gXj0zTSKU5dfAuZt7qUj6YtewfK0CU=`），
`attic cache info public` 会给完整串。

必须用 `extra-*`：`trusted-public-keys` 会被 flake 的 `nixConfig` 覆盖。

## 运维

```bash
cd /opt/NixOS-Config/services/attic

docker compose ps                        # 状态
docker compose logs -f --tail 100 atticd # 日志
du -sh /srv/atticd/storage               # 落盘占用
df -h /                                  # 磁盘余量（>80% 缩保留期）

# 手工 GC
docker compose exec atticd atticd --mode garbage-collector-once

# 缩短保留期
attic cache configure --retention-period 14d public

# DB 备份（timer 每日自动，也可手工）
systemctl start atticd-backup.service ; ls -lt /srv/atticd/backups | head

# 升级 Attic（等同 DB 迁移，先备份！）
#   1. 改 docker-compose.yml 里的 image digest
#   2. systemctl start atticd-backup.service
#   3. docker compose up -d
#   4. 回滚 = digest 改回旧值 + 恢复 DB 备份
```

## 故障排查

| 现象 | 原因 | 处置 |
| --- | --- | --- |
| 上传返回 413（页面带 cloudflare） | 把推送发去了 CF 域 | `api-endpoint` 必须指 `https://push.rhen.cloud/` |
| 上传返回 413（页面无 cloudflare） | `client_max_body_size` 太小 | AcePanel 站点 server 块设成 0 |
| `InvalidHost` / 400 | `allowed-hosts` 与实际域名不符 | 改 `server.toml` 后重启容器 |
| 推送 502 / 容器反复重启 | `mem_limit` 太小，推大包时 OOM（`dmesg` 有 `Killed process atticd`） | 已调成 `2g`；zstd level 已从 19 降到 8 |
| 客户端报无签名，全量回退编译 | 公钥没进 `extra-trusted-public-keys` | 补公钥后重跑 |
| 缓存体积远超预期 | 没登记上游 key，公共包也被存 | 检查日志里是否出现 `N in upstream` |
| 502 | atticd 没起来 / 端口不对 | `curl 127.0.0.1:8080/nix-cache-info` |
| 令牌 401 | 私钥被重新生成 | 用同一私钥重发令牌 |
| `database is locked` | SQLite 只允许单实例 | 不要横向扩副本 |
