{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.server.install;
in
{
  imports = [
    inputs.disko.nixosModules.disko
    {
      config.boot.supportedFilesystems = [ "btrfs" ];
    }
  ];

  options.rhencloud.server = {
    install = {
      enable = mkEnableOption "nixos-anywhere 安装模式（启用 disko 磁盘布局）";
      disk = mkOption {
        type = types.str;
        default = "/dev/vda";
        description = "目标磁盘设备";
      };
    };
    ssh = {
      port = mkOption {
        type = types.port;
        default = 45855;
        description = "SSH 监听端口";
      };
    };
  };

  config = mkIf cfg.enable {
    disko.devices = {
      disk.main = {
        type = "disk";
        device = cfg.disk;
        content = {
          type = "gpt";
          partitions = {
            bios_boot = {
              size = "1M";
              type = "EF02";
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "btrfs";
                mountpoint = "/";
                mountOptions = [
                  "noatime"
                  "compress=zstd"
                  "space_cache=v2"
                  "subvolid=5"
                ];
              };
            };
          };
        };
      };
    };

    # 创建 Btrfs 子卷并配置 QGROUP 配额，防止单路径耗尽系统空间
    systemd.tmpfiles.rules = [
      "d /home 755 root root -"
      "d /var/log 755 root root -"
      "d /snapshots 755 root root -"
      "d /var/lib/postgresql 700 postgres postgres -"
      "d /var/lib/nextcloud 700 nextcloud nextcloud -"
      "d /var/lib/vaultwarden 700 vaultwarden vaultwarden -"
    ];

    systemd.services."btrfs-setup" = {
      description = "Create Btrfs subvolumes and configure quotas";
      wantedBy = [
        "multi-user.target"
        "local-fs.target"
      ];
      after = [ "local-fs.target" ];
      path = [ pkgs.btrfs-progs ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        btrfs subvolume create /home || true
        btrfs subvolume create /var/log || true
        btrfs subvolume create /snapshots || true
        btrfs subvolume create /var/lib/postgresql || true
        btrfs subvolume create /var/lib/nextcloud || true
        btrfs subvolume create /var/lib/vaultwarden || true
        btrfs qgroup create 0/5 || true
        btrfs qgroup assign 5/6 /home || true
        btrfs qgroup assign 5/7 /var/log || true
        btrfs qgroup assign 5/8 /snapshots || true
        btrfs qgroup assign 5/9 /var/lib/postgresql || true
        btrfs qgroup assign 5/10 /var/lib/nextcloud || true
        btrfs qgroup assign 5/11 /var/lib/vaultwarden || true
      '';
    };
  };
}
