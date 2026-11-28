#!/usr/bin/env bash
# wechat overlay 的自定义 hash 刷新器（由 scripts/auto-update.sh 调用）。
#
# 背景：微信 Linux 版的下载地址是固定 URL（WeChatLinux_x86_64.AppImage，
# 不带版本号），腾讯发新版时原地替换文件，旧 hash 必然失效，nix-update
# 也无法从这种 URL 推断版本。这里直接拉取当前文件的 hash 写回 overlay，
# hash 一致即视为「已是最新」。
#
# 用法：update-wechat-hash.sh <工作目录>
#   工作目录是 auto-update.sh 复制出来的仓库副本（path flake），
#   本脚本只改其中的 overlays/wechat/default.nix。
#
# 退出码：0 = 成功（无论是否改动），非 0 = 失败（调用方回滚快照）。

set -euo pipefail

ws="${1:?用法: update-wechat-hash.sh <工作目录>}"
file="$ws/overlays/wechat/default.nix"

if [ ! -f "$file" ]; then
  echo "找不到 $file" >&2
  exit 1
fi

url=$(grep -oP 'url = "\K[^"]+' "$file" | head -1)
current=$(grep -oP 'hash = "\K[^"]+' "$file" | head -1)

if [ -z "$url" ] || [ -z "$current" ]; then
  echo "无法从 $file 解析 url/hash 字段" >&2
  exit 1
fi

echo "  拉取 $url 计算 hash（约 300MB）"
# nix store prefetch-file 输出 SRI 格式 hash，与文件里写法一致。
# 文件名带扩展名，避免 nix 把内容当 tar 包递归解压后算错对象。
new_hash=$(nix store prefetch-file --json --name "WeChatLinux_x86_64.AppImage" "$url" |
  jq -r '.hash // empty' 2>/dev/null || true)

if [ -z "$new_hash" ]; then
  echo "prefetch 失败或未得到 hash" >&2
  exit 1
fi

if [ "$new_hash" = "$current" ]; then
  echo "  hash 未变化（$current）"
  exit 0
fi

sed -i "s|hash = \"$current\"|hash = \"$new_hash\"|" "$file"
echo "  hash 更新：$current -> $new_hash"
