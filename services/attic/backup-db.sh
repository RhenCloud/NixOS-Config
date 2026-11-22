#!/usr/bin/env bash
# 备份 Attic 的 SQLite 数据库。server.db 里有缓存签名私钥，是唯一不可重建的东西
# （NAR 丢了可以重新推，私钥丢了所有客户端公钥都要改）。
#
# 用 sqlite3 .backup 做在线备份，不需要停容器。
set -euo pipefail

DB=/srv/atticd/data/server.db
DEST=/srv/atticd/backups
KEEP=14
# 可选：远端备份目标，例如 rhencloud@yc-hk-1:/var/backups/atticd/
REMOTE=${ATTIC_BACKUP_REMOTE:-}

[ -f "$DB" ] || {
	printf 'not found: %s\n' "$DB" >&2
	exit 1
}
install -d -m 0700 "$DEST"

stamp=$(date -u +%Y%m%dT%H%M%SZ)
out="$DEST/server-$stamp.db"
sqlite3 "$DB" ".backup '$out'"
chmod 0600 "$out"

# 只保留最近 KEEP 份
find "$DEST" -maxdepth 1 -name 'server-*.db' -printf '%T@ %p\n' |
	sort -rn | tail -n "+$((KEEP + 1))" | cut -d' ' -f2- | xargs -r rm -f

if [ -n "$REMOTE" ]; then
	rsync -az --delete "$DEST/" "$REMOTE"
fi

printf 'backup ok: %s (%s)\n' "$out" "$(du -h "$out" | cut -f1)"