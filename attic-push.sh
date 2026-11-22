#!/usr/bin/env bash
# Attic 推送脚本：把给定的 store 路径推到 cache.rhen.cloud
#
# 上游过滤交给 Attic 自己（缓存已登记 6 个上游 key，push 时会报
# `0 already cached, N in upstream`）。不要在这里做 narinfo 预查：
# 实测 nixos-desktop 闭包里 236 个路径上游确实有，但只占 0.21 GiB（2%），
# 预查纯属浪费请求。
#
# 注意端点分工：
#   ATTIC_SERVER 必须是 https://push.rhen.cloud（直连），不能用 cache.rhen.cloud
#   —— 后者走 Cloudflare，免费版单请求 100 MB 上限，GB 级包必 413。
#   客户端拉取用 https://cache.rhen.cloud/public，两者由服务端
#   api-endpoint / substituter-endpoint 分别下发。

set -euo pipefail

ATTIC_SERVER="${ATTIC_SERVER:-https://push.rhen.cloud}"
ATTIC_CACHE="${ATTIC_CACHE:-public}"
ATTIC_TOKEN="${ATTIC_TOKEN:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

usage() {
    cat <<HELP
用法: $0 [选项] [store 路径...]

不传路径时推送 \`nix build .# --print-out-paths\` 的结果。

选项:
  --help, -h          显示此帮助
  --server URL        API/推送入口（默认: ${ATTIC_SERVER}）
  --cache NAME        缓存名（默认: ${ATTIC_CACHE}）
  --token TOKEN       Attic 令牌

环境变量:
  ATTIC_TOKEN         Attic 访问令牌（必需）
  ATTIC_SERVER        API/推送入口（默认: https://push.rhen.cloud）
  ATTIC_CACHE         缓存名（默认: public）

示例:
  ATTIC_TOKEN=xxx $0
  ATTIC_TOKEN=xxx $0 /nix/store/xxx-foo-1.0
HELP
}

main() {
    if [ -z "$ATTIC_TOKEN" ]; then
        print_error "ATTIC_TOKEN 未设置"
        exit 1
    fi

    local -a paths=("$@")
    if [ ${#paths[@]} -eq 0 ]; then
        print_info "构建 .# ..."
        mapfile -t paths < <(nix build .# --no-link --print-out-paths)
    fi
    if [ ${#paths[@]} -eq 0 ]; then
        print_error "没有可推送的路径"
        exit 1
    fi

    print_info "入口: $ATTIC_SERVER  缓存: $ATTIC_CACHE  路径数: ${#paths[@]}"
    # 本地代理会拦 POST，attit 的 API 请求必须直连
    env -u http_proxy -u https_proxy -u all_proxy \
        nix run nixpkgs#attic-client -- login rhen "$ATTIC_SERVER" "$ATTIC_TOKEN" --set-default
    env -u http_proxy -u https_proxy -u all_proxy \
        nix run nixpkgs#attic-client -- push "rhen:${ATTIC_CACHE}" "${paths[@]}"
    print_success "推送完成"
}

if [ $# -gt 0 ]; then
    case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
    esac
fi

args=()
while [ $# -gt 0 ]; do
    case "$1" in
        --server)
            ATTIC_SERVER="$2"
            shift 2
            ;;
        --cache)
            ATTIC_CACHE="$2"
            shift 2
            ;;
        --token)
            ATTIC_TOKEN="$2"
            shift 2
            ;;
        --*)
            print_error "未知选项: $1"
            exit 1
            ;;
        *)
            args+=("$1")
            shift
            ;;
    esac
done

main "${args[@]}"