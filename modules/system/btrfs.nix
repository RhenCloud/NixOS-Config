{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhencloud.btrfs;
in
{
  options.rhencloud.btrfs = {
    enable = mkEnableOption "启用 Btrfs 配额和配置" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    # 启用 Btrfs 配额（防止单路径耗尽系统空间）
    boot.kernelPackages = config.boot.kernelPackages;

    # 执行 Btrfs 配额设置的服务
    systemd.services."btrfs-quota-enable" = {
      description = "启用 Btrfs 配额";
      wantedBy = [ "multi-user.target" ];
      wantedBy = [ "local-fs.target" ];
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "+btrfs quota enable /";
      };
    };

    # 服务确保配额和子卷配置
    systemd.services."btrfs-quota-setup" = {
      description = "配置 Btrfs 子卷配额";
      wantedBy = [ "multi-user.target" ];
      wantedBy = [ "local-fs.target" ];
      after = [ "btrfs-quota-enable.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          # 配置 QGROUP 和子卷配额
          for subvol in '/home' '/var/log' '/snapshots' '/var/lib/postgresql' '/var/lib/nextcloud' '/var/lib/vaultwarden'; do
            if [ -d "$subvol" ]; then
              subvol_id=$(findmnt -n -o SUBVOLUME-ID "$subvol" 2>/dev/null || echo "")
              if [ -n "$subvol_id" ] && [ "$subvol_id" != "5" ]; then
                # 使用子卷名称的“逻辑用户”减少浪费：0/(50 + (base10_1的个位))
                subvol_name=$(basename "$subvol")
                subvol_suffix=""
                if [ "$subvol_name" = "home" ]; then
                  subvol_suffix=6
                elif [ "$subvol_name" = "log" ]; then
                  subvol_suffix=7
                elif [ "$subvol_name" = "snapshots" ]; then
                  subvol_suffix=8
                elif [ "$subvol_name" = "postgresql" ]; then
                  subvol_suffix=9
                elif [ "$subvol_name" = "nextcloud" ]; then
                  subvol_suffix=10
                elif [ "$subvol_name" = "vaultwarden" ]; then
                  subvol_suffix=11
                fi

                qgroup_id="0/$subvol_suffix"

                # 删除已存在的 QGROUP
                btrfs qgroup destroy "$qgroup_id" 2>/dev/null || true

                # 创建 QGROUP 并分配子卷
                btrfs qgroup create "$qgroup_id"
                btrfs qgroup assign "$qgroup_id" "$subvol_id"
              fi
            fi
          done
        '';
      };
    };

    # 群组依赖：quota-enable 在 quota-setup 之后执行
    systemd.services."btrfs-quota-enable".wantedBy = [
      "btrfs-quota-setup.service"
    ];

    # 文档和工具
    environment.systemPackages = with pkgs; [
      btrfs-progs
    ];

    # 记录配置的日志
    systemd.services."btrfs-quota-setup".restartTriggers = [
      "/etc/btrfs/quota.conf"
    ];
  };
}
