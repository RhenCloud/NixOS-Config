#!/usr/bin/env nix-shell
# nix-shell -p btrfs-progs --run "./btrfs-fix.sh"

# Btrfs 检查与修复脚本
# 使用前提：需要以 root 身份运行，或 sudo ./btrfs-fix.sh

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查当前挂载点
check_mountpoint() {
local mountpoint=$1
if ! mountpoint -q "$mountpoint"; then
  log_warn "$mountpoint 未挂载，跳过检查"
  return
fi

log_info "检查 $mountpoint 的 Btrfs 状态..."
echo -e "\n=== $mountpoint ==="

# 显示总体使用情况
btrfs fi usage "$mountpoint" | head -n 30

# 查看各子卷大小
echo -e "\n子卷列表："
btrfs subvolume list -s "$mountpoint" | awk '{print "  - " $NF}'

# 查看配额
echo -e "\n配额统计："
btrfs qgroup show -r "$mountpoint"

# 查看压缩效果
echo -e "\n压缩统计："
btrfs fi df "$mountpoint"
}

# 检查是否启用 space cache v2
check_space_cache() {
local dev=$1
if [ -f "/sys/fs/btrfs/${dev}/space/cache/v2" ]; then
  log_info "space_cache=v2 已启用 for $dev"
else
  log_warn "space_cache=v2 未启用，尝试挂载时添加"
fi
}

# 列出日志子卷（3MB 总使用）
check_log_subvol() {
local mountpoint=$1
local log_subvols=$(btrfs subvolume list -s "$mountpoint" | grep log)
if [ -n "$log_subvols" ]; then
  log_info "发现日志子卷："
  btrfs subvolume show $log_subvols
else
  log_warn "未发现日志子卷"
fi
}

# 检查是否有耗尽的空间
check_space_full() {
local mountpoint=$1
local usage=$(btrfs fi usage --raw "$mountpoint" 2>/dev/null | awk '/Data,/ {split($3,size,"("); print int(size[1])}')
local total=$(btrfs fi show "$mountpoint" 2>/dev/null | awk '/UUID:/ {print $2}')
[[ -n "$usage" && -n "$total" ]] && log_info "设备总容量使用: $(echo "scale=1; 100 * $usage / $total" | bc)%" || log_info "无法获取容量信息"
}

# 检查是否有 orphan 空间
check_orphans() {
local mountpoint=$1
local used=$(btrfs property get "$mountpoint" used | awk '{print $2}')
local free=$(btrfs property get "$mountpoint" free | awk '{print $2}')
log_info "used: $used, free: $free"
}

# 创建 QGROUP（如果尚未创建）
# 注意：需要先确保 subvolumes 已存在
ensure_qgroups() {
local mountpoint=$1

log_info "检查 QGROUP 是否已配置..."

# 检查根 qgroup
if ! btrfs qgroup list "$mountpoint" | grep -q "^0/5"; then
  log_warn "未找到根 qgroup (0/5)，尝试创建..."
  btrfs qgroup create 0/5 "$mountpoint"
else
  log_info "根 qgroup (0/5) 已存在"
fi

# 为每个子卷创建分配
local subvols=(
  "/home"
  "/var/log"
  "/snapshots"
  "/var/lib/postgresql"
  "/var/lib/nextcloud"
  "/var/lib/vaultwarden"
)

for subvol in "${subvols[@]}"; do
  if [ -d "$mountpoint$subvol" ]; then
    local vol_id=$(btrfs subvolume show "$mountpoint$subvol" | grep ' subtreeid:' | awk '{print $2}')
    local qgroup_id=$(echo "5$((random % 20 + 26))")  # 生成 5X 的 QGROUP ID

    log_info "配置 $subvol"

    # 先删除可能存在的旧 QGROUP
    btrfs qgroup destroy "${qgroup_id}" "$mountpoint" 2>/dev/null || true

    # 创建新 qgroup
    btrfs qgroup create "${qgroup_id}" "$mountpoint"
    btrfs qgroup assign "${qgroup_id}" "${vol_id}" "$mountpoint"

    log_info "  创建了 QGROUP ${qgroup_id} for $subvol"
  fi
done
}

# 清理空间碎片（挂载状态）
balance_space() {
local mountpoint=$1

log_warn "开始空间重构（到 50% 使用率的目标）..."
btrfs filesystem balance "$mountpoint" -dusage=50 -musage=80 2>&1 | tail -n 20
log_info "空间重构完成"
}

# 调整 metadata_ratio（文件系统需为空）
tune_metadata() {
local mountpoint=$1
local ratio=${2:-1}

log_warn "调整 metadata_ratio 到 ${ratio}%（请在文件系统无其他数据时执行，谨慎操作！)"
read -p "是否继续？ [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  btrfs tune -M "$ratio" "$mountpoint"
fi
}

# 主流程
main() {
  echo -e "\n╔════════════════════════════════════════════════════════╗"
  echo -e "║           Btrfs 空间检查与修复脚本                      ║"
  echo -e "╚════════════════════════════════════════════════════════╝"

  # 检查 root 挂载
  if [ "$EUID" -ne 0 ]; then
    log_error "需要 root 权限运行此脚本"
    log_info "请使用 sudo ./btrfs-fix.sh"
    exit 1
  fi

  # 检查 Btrfs 支持
  if [ ! -d "/sys/fs/btrfs" ]; then
    log_error "当前系统不支持 Btrfs"
    exit 1
  fi

  # 检查根挂载点
  if ! mountpoint -q "/"; then
    log_error "根文件系统未挂载"
    exit 1
  fi

  # 执行检查
  check_mountpoint "/"
  check_space_cache "root"
  check_log_subvol "/"
  check_space_full "/"

  # 交互式修复菜单
  echo -e "\n=== 修复选项 ==="
  echo "1) 永久配置空间碎片（需要重启）"
  echo "2) 调整 QGROUP 配额（动态）"
  echo "3) 执行空间重构（挂载时）"
  echo "4) 调整 metadata_ratio（文件系统需无数据，谨慎）"
  echo "5) 显示所有选项描述"
  echo "q) 退出"

  read -p "选择操作 [1-5]: " choise

  case $choise in
    1)
      read -p "空间碎片重构到 50%<yes/no>]: " setup_fb
      if [[ "$setup_fb" =~ ^[Yy]$ ]]; then
        systemd-run --server-config /run/systemd/system.conf \
            --machine-id $HOSTNAME \
            --boot \
            --property=Restart=no \
            --scope btrfs-reset --filesystem=/ \
            btrfs filesystem balance / -dusage=50 -musage=80
      fi
      ;;
    2)
      ensure_qgroups "/"
      read -p "是否重新读取配置？需要重启："
      ;;
    3)
      balance_space "/"
      ;;
    4)
      read -p "metadata_ratio [1-5]: " meta_ratio
      tune_metadata "/" "$meta_ratio"
      ;;
    5)
      echo -e "\n空间碎片（不可回滚，需要重启）："
      echo "  systemd-run btrfs-reset --filesystem=/ btrfs filesystem balance / -dusage=50 -musage=80"
      echo -e "\nQGROUP 配额（动态生效）："
      echo "  btrfs qgroup create 0/5"
      echo "  btrfs qgroup add -e 0/6 /home"
      echo "  btrfs qgroup add -e 0/7 /var/log"
      echo -e "\n空间重构（挂载时）："
      echo "  btrfs filesystem balance / -dusage=50 -musage=80"
      echo -e "\nmetadata_ratio（需文件系统空）："
      echo "  btrfs tune -M 1 /"
      ;;
    *)
      log_info "已取消操作"
      ;;
  esac

  log_info "检查完成，建议每月执行一次："
  echo "  sudo ./btrfs-check.sh"
}

# 独立运行检查函数（来自待验证函数）
check_mountpoint_orphans() {
  if [ "$EUID" -ne 0 ]; then
    log_error "需要 root 权限"
    exit 1
  fi

  if ! mountpoint -q "/home" 2>/dev/null; then
    log_warn "/home 未挂载"
    return
  fi

  echo "检查 /home 的 orphan 策略："
  if btrfs property get /home noatime 2>/dev/null | grep -q noatime; then
    echo "  ✓ noatime 已设置"
  else
    btrfs property set /home noatime
  fi
}

case "${1:-all}" in
  check)
    check_mountpoint "/"
    check_space_cache "root"
    ;;
  fix)
    if ! mountpoint -q "/"; then
      log_error "根文件系统未挂载，无法修复"
      exit 1
    fi

    # 确保配额已配置
    ensure_qgroups "/"

    # 清理空间碎片
    balance_space "/"

    log_info "修复完成，建议重启服务器"
    ;;
  check-orphans)
    check_mountpoint_orphans
    ;;
  *)
    main "$@"
    ;;
esac