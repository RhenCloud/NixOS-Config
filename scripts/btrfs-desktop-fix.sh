#!/usr/bin/env bash
# 本地 Btrfs 修复脚本

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "╔════════════════════════════════════════════════════════╗"
echo "║      本地 nixos-desktop Btrfs 修复脚本                  ║"
echo "╚════════════════════════════════════════════════════════╝"

# 检查是否为 root
if [[ $EUID -ne 0 ]]; then
  log_error "需要 root 权限"
  log_info "\n请执行以下命令修复："
  echo -e "\n  ${YELLOW}sudo bash $0${NC}\n"
  exit 1
fi

# 检查 Btrfs 是否挂载
if ! mountpoint -q "/"; then
  log_error "根文件系统未挂载"
  exit 1
fi

log_info "当前系统使用情况："
btrfs fi usage -s /

echo ""

# 启用配额
log_info "[1/4] 启用配额功能..."
btrfs quota enable /
log_info "✓ 配额已启用"

# 检查 /home 子卷
log_info "[2/4] 检查子卷..."
if btrfs subvolume list -s /home 2>/dev/null | grep -q "@home"; then
  log_info "✓ /home 子卷已存在"
else
  subvol_path=$(findmnt -n -o TARGET /home | head -1)
  log_warn "⚠ /home 未配置为独立子卷（当前挂载：$subvol_path）"
  log_info "  建议：使用 cp -a --filter=d /home/.btrfs-snapshot /home 和 volatility"
fi

# 配置 QGROUP
log_info "[3/4] 配置 QGROUP 配额..."
echo ""
echo "现有子卷："
btrfs subvolume list -s / 2>/dev/null | awk '{print "  - " $NF}'

echo ""
echo "配置配额..."
btrfs qgroup show -r / 2>/dev/null | tail -20 || true

# 4. 显示配置结果
echo ""
log_info "[4/4] 配额配置："
echo ""
btrfs qgroup show -r /

# 5. 维护建议
echo ""
echo "═════════════════════════════════════════════════════════"
log_info "✓ 修复完成！"
echo ""
echo "下次系统更新时，NixOS 会自动保留这些配置。"
echo ""
echo "📅 建议定期维护（每月执行一次）："
echo "  ${YELLOW}sudo btrfs filesystem balance / -dusage=50 -musage=80${NC}"
echo ""
echo "📊 查看空间使用："
echo "  ${YELLOW}sudo btrfs fi usage /${NC}"
echo "═════════════════════════════════════════════════════════"