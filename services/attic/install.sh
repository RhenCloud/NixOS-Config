#!/usr/bin/env bash
# Attic 缓存服务的安装脚本（Debian/Ubuntu + Docker Compose）。
# 幂等：可重复执行，已存在的私钥与数据不会被覆盖。
#
# 本机已是 Debian 13：80/443 由 AcePanel 的 nginx 接管（2026-11-22 从 1Panel OpenResty 迁过来），
# atticd 只监听 127.0.0.1:8080，TLS 与对外入口在 AcePanel 站点里配（见 push.rhen.cloud.conf）。
#
# 用法（在服务器上，root）：
#   git clone https://github.com/RhenCloud/NixOS-Config /opt/NixOS-Config
#   /opt/NixOS-Config/services/attic/install.sh
set -euo pipefail

SRC_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DATA_ROOT=/srv/atticd
DOMAIN=cache.rhen.cloud

log() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "请用 root 运行"

# ---------------------------------------------------------------- 依赖
if ! command -v docker >/dev/null 2>&1; then
	log "安装 docker / compose / sqlite3 / rsync"
	apt-get update -qq
	DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
		docker.io docker-compose-v2 sqlite3 rsync curl ca-certificates
fi
docker compose version >/dev/null 2>&1 || die "需要 docker compose v2"
command -v openssl >/dev/null || die "缺少 openssl"

# ---------------------------------------------------------------- 目录
log "创建 $DATA_ROOT"
install -d -m 0755 "$DATA_ROOT"/data "$DATA_ROOT"/storage "$DATA_ROOT"/backups

# ---------------------------------------------------------------- JWT 私钥
if [ ! -s "$SRC_DIR/atticd.env" ]; then
	log "生成 RS256 JWT 私钥 -> atticd.env"
	secret=$(openssl genrsa -traditional 4096 | base64 -w0)
	(
		umask 077
		printf 'ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64=%s\n' "$secret" \
			> "$SRC_DIR/atticd.env"
	)
	printf '!! 把 atticd.env 里的私钥加密备份到 secrets/hosts/hd-sg-1.yaml\n'
else
	log "atticd.env 已存在，保留原私钥"
fi

# ---------------------------------------------------------------- 校验配置
log "atticd check-config"
docker compose -f "$SRC_DIR/docker-compose.yml" run --rm \
	atticd -f /attic/server.toml --mode check-config

# ---------------------------------------------------------------- 启动
log "启动容器"
docker compose -f "$SRC_DIR/docker-compose.yml" up -d --pull always

# ---------------------------------------------------------------- 防火墙
# 本机没装 ufw（1Panel 自己管防火墙），80/443 由 OpenResty 监听，无需额外放行

# ---------------------------------------------------------------- 备份 timer
if command -v systemctl >/dev/null 2>&1; then
	log "安装每日 DB 备份 timer"
	install -m 0755 "$SRC_DIR/backup-db.sh" /usr/local/bin/atticd-backup
	install -m 0644 "$SRC_DIR/atticd-backup.service" \
		/etc/systemd/system/atticd-backup.service
	install -m 0644 "$SRC_DIR/atticd-backup.timer" \
		/etc/systemd/system/atticd-backup.timer
	systemctl daemon-reload
	systemctl enable --now atticd-backup.timer
fi

# ---------------------------------------------------------------- 自检
log "本机自检"
for _ in $(seq 1 20); do
	if curl -fsS "http://127.0.0.1:8080/nix-cache-info"; then
		break
	fi
	sleep 2
done

log "对外自检（需要 1Panel 站点已配好）"
curl -fsS "https://$DOMAIN/nix-cache-info" ||
	printf '1Panel 站点/证书未就绪，先在面板里完成反向代理配置\n'

cat <<EOF

下一步（一次性初始化）：

  cd $SRC_DIR
  # 1) CI 令牌 -> GitHub repo secret ATTIC_PUSH_TOKEN
  docker compose exec atticd atticadm make-token \\
    --sub ci --validity 2y --pull '*' --push 'public'

  attic cache create --public public \\
    --upstream-cache-key-name cache.nixos.org-1 \\
    --upstream-cache-key-name nix-community.cachix.org-1 \\
    --upstream-cache-key-name hyprland.cachix.org-1 \\
    --upstream-cache-key-name niri.cachix.org-1 \\
    --upstream-cache-key-name noctalia.cachix.org-1 \\
    --upstream-cache-key-name vicinae.cachix.org-1

  attic cache info public      # 记下 Priority 与公钥，填进 flake.nix

EOF