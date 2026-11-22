#!/usr/bin/env bash
# 定期升级 packages/* 自有包的版本。
#
# 设计要点：
#   1. 在**无 .git 的临时目录**里跑 nix-update。
#      脏 git 树时 `nix flake metadata --json` 不返回 path，
#      nix-update 会报 "opening file /nix/store/xxx-source: No such file"。
#      用 git archive 出来的纯目录（path flake）则一定拿得到 path。
#      顺带避开 wallpapers submodule（1 GB 图包，nix 代码里没人读它）。
#   2. 每个包独立 try → verify → 回滚。一个包升级失败不影响其他包。
#   3. 只有 `nix-update --build` 成功（新版能编出来）才写回工作树。
#
# 用法：
#   ./scripts/auto-update.sh              # 正常升级并写回
#   DRY_RUN=1 ./scripts/auto-update.sh    # 只报告，不写回
set -uo pipefail

WS=${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel)}
LIST=${AUTO_UPDATE_LIST:-$WS/.github/auto-update-packages.txt}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if [ ! -f "$LIST" ]; then
  echo "找不到白名单 $LIST" >&2
  exit 1
fi

# 工作树脏时提示但继续：只在单个包回滚时用 `cp` 恢复快照，不用 git checkout，
# 因此不会抹掉你未提交的改动。
if ! git -C "$WS" diff --quiet || ! git -C "$WS" diff --cached --quiet; then
  echo "警告：工作树有未提交改动，回滚仅按文件快照进行" >&2
fi

echo "==> 导出工作树副本到 $TMP"
# 用工作树（而非 git archive HEAD）：本地跑时未提交的改动也应参与升级，
# CI 里工作树就是 checkout，两种情形行为一致。
# 排除 .git 与 wallpapers submodule（脏 git 树会让 nix flake metadata 没有 path）。
tar -C "$WS" -cf - \
  --exclude=./.git \
  --exclude=./wallpapers \
  --exclude=./result \
  --exclude=./result-* \
  . | tar -x -C "$TMP"

ok=0
fail=0
skip=0
: >"$TMP/.changed"

while read -r line; do
  line=${line%%#*}
  line=$(echo "$line" | xargs) # 去首尾空白
  [ -z "$line" ] && continue

  pkg=${line%% *}
  extra=""
  [ "$pkg" != "$line" ] && extra=${line#"$pkg"}

  file="packages/$pkg/default.nix"
  if [ ! -f "$WS/$file" ]; then
    echo "SKIP $pkg（找不到 $file）"
    skip=$((skip + 1))
    continue
  fi

  before=$(cat "$TMP/$file")
  old_ver=$(grep -oP 'version = "\K[^"]+' "$TMP/$file" | head -1)

  # shellcheck disable=SC2086
  if ! (cd "$TMP" && nix-update --flake --quiet --build $extra "$pkg"); then
    echo "FAIL $pkg（升级或构建失败，已跳过）"
    printf '%s' "$before" >"$TMP/$file"
    fail=$((fail + 1))
    continue
  fi

  after=$(cat "$TMP/$file")
  if [ "$before" = "$after" ]; then
    echo "SAME $pkg（已是最新）"
    skip=$((skip + 1))
    continue
  fi

  new_ver=$(grep -oP 'version = "\K[^"]+' "$TMP/$file" | head -1)

  # 假升级守卫：nix-update 只改 version 字段，不会重写写死在 url 里的版本。
  # 若旧版本字符串仍然残留在文件里（典型：fetchurl 的 url 写成 v1.2.3），
  # 说明 upgrade 不完整（version 标签对不上实际下载物）→ 回滚并提示改模板。
  if [ -n "$old_ver" ] && [ "$old_ver" != "$new_ver" ] &&
    grep -qF "$old_ver" "$TMP/$file"; then
    echo "FAIL $pkg（旧版本 $old_ver 仍残留在 url 等处，需改成 \${version} 模板）"
    printf '%s' "$before" >"$TMP/$file"
    fail=$((fail + 1))
    continue
  fi

  version=$new_ver
  if [ "${DRY_RUN:-0}" = 1 ]; then
    echo "DRY  $pkg → ${version:-?}（未写回）"
  else
    cp "$TMP/$file" "$WS/$file"
    echo "OK   $pkg → ${version:-?}"
    echo "$file" >>"$TMP/.changed"
  fi
  ok=$((ok + 1))
done <"$LIST"

if [ "${DRY_RUN:-0}" != 1 ] && [ -s "$TMP/.changed" ]; then
  echo "==> 格式化改动文件"
  # shellcheck disable=SC2046
  nix fmt -- $(cat "$TMP/.changed") >/dev/null 2>&1 || echo "nix fmt 失败，稍后由 format-lint 兜底"
fi

echo "==> 汇总：$ok 升级，$fail 失败，$skip 无变化/跳过"
[ "$ok" -gt 0 ] && exit 0
exit 0