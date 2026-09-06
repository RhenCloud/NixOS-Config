#!/usr/bin/env bash
# Attic 智能推送脚本
# 只推送上游未缓存的包

set -euo pipefail

# 配置
ATTIC_SERVER="${ATTIC_SERVER:-https://cache.rhen.cloud}"
ATTIC_CACHE="${ATTIC_CACHE:-public}"
ATTIC_TOKEN="${ATTIC_TOKEN:-}"
UPSTREAM_CACHE="${UPSTREAM_CACHE:-https://cache.nixos.org}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函数：打印颜色文本
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_skip() { echo -e "${YELLOW}⏭️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# 检查必要的工具
check_dependencies() {
    command -v nix &> /dev/null || { print_error "nix 未安装"; exit 1; }
    command -v curl &> /dev/null || { print_error "curl 未安装"; exit 1; }
}

# 检查令牌
check_token() {
    if [ -z "$ATTIC_TOKEN" ]; then
        print_error "ATTIC_TOKEN 未设置"
        echo "请设置: export ATTIC_TOKEN=your-token"
        exit 1
    fi
}

# 检查包是否在上游缓存中
is_in_upstream_cache() {
    local store_path="$1"
    local store_hash=$(basename "$store_path" | cut -d- -f1)
    
    # 查询上游缓存
    if curl -s "${UPSTREAM_CACHE}/${store_hash}.narinfo" > /dev/null 2>&1; then
        return 0  # 存在
    else
        return 1  # 不存在
    fi
}

# 主函数
main() {
    print_info "Attic 智能推送工具"
    print_info "服务器: $ATTIC_SERVER"
    print_info "缓存: $ATTIC_CACHE"
    print_info "上游: $UPSTREAM_CACHE"
    echo ""
    
    # 检查依赖
    check_dependencies
    check_token
    
    # 构建项目
    print_info "构建项目..."
    STORE_PATHS=$(nix build .# --print-out-paths 2>/dev/null)
    
    if [ -z "$STORE_PATHS" ]; then
        print_error "构建失败或未生成输出"
        exit 1
    fi
    
    echo ""
    print_info "构建完成，共 $(echo "$STORE_PATHS" | wc -l) 个包"
    echo ""
    
    # 登录
    print_info "登录 Attic..."
    nix shell github:zhaofengli/attic --run attic login \
        --server "$ATTIC_SERVER" \
        "$ATTIC_CACHE" \
        "$ATTIC_TOKEN" 2>/dev/null || {
        print_error "登录失败"
        exit 1
    }
    print_success "已登录"
    echo ""
    
    # 推送包
    local pushed_count=0
    local skipped_count=0
    local failed_count=0
    
    print_info "开始推送..."
    echo ""
    
    while IFS= read -r path; do
        if is_in_upstream_cache "$path"; then
            print_skip "跳过 (上游已有): $path"
            ((skipped_count++))
        else
            if nix shell github:zhaofengli/attic --run attic push \
                "$ATTIC_CACHE" "$path" 2>/dev/null; then
                print_success "推送成功: $path"
                ((pushed_count++))
            else
                print_error "推送失败: $path"
                ((failed_count++))
            fi
        fi
    done <<< "$STORE_PATHS"
    
    # 统计
    echo ""
    echo "================================"
    print_success "已推送: $pushed_count 个包"
    print_skip "已跳过: $skipped_count 个包"
    if [ $failed_count -gt 0 ]; then
        print_error "失败: $failed_count 个包"
    fi
    echo "================================"
    
    if [ $failed_count -eq 0 ]; then
        print_success "推送完成！"
        return 0
    else
        print_error "部分推送失败"
        return 1
    fi
}

# 处理命令行参数
if [ $# -eq 0 ]; then
    main
elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    cat << HELP
用法: $0 [选项]

选项:
  --help, -h              显示此帮助
  --server URL            Attic 服务器地址 (默认: https://cache.rhen.cloud)
  --cache NAME            缓存名称 (默认: public)
  --upstream URL          上游缓存地址 (默认: https://cache.nixos.org)
  --token TOKEN           Attic 令牌

环境变量:
  ATTIC_TOKEN             Attic 访问令牌 (必需)
  ATTIC_SERVER            Attic 服务器 (默认: https://cache.rhen.cloud)
  ATTIC_CACHE             缓存名称 (默认: public)
  UPSTREAM_CACHE          上游缓存 (默认: https://cache.nixos.org)

示例:
  $0
  ATTIC_TOKEN=xxx $0
  $0 --server https://custom-cache.com --cache my-cache

HELP
else
    # 解析参数
    while [ $# -gt 0 ]; do
        case "$1" in
            --server) ATTIC_SERVER="$2"; shift 2 ;;
            --cache) ATTIC_CACHE="$2"; shift 2 ;;
            --upstream) UPSTREAM_CACHE="$2"; shift 2 ;;
            --token) ATTIC_TOKEN="$2"; shift 2 ;;
            *) print_error "未知选项: $1"; exit 1 ;;
        esac
    done
    main
fi
