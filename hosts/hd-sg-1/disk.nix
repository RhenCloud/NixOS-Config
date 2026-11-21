{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhen.server.install;
in
{
  imports = [
    inputs.disko.nixosModules.disko
    { config.boot.supportedFilesystems = [ "btrfs" ]; }
  ];

  options.rhen.server.install = {
    enable = mkEnableOption "nixos-anywhere 安装模式";
    disk = mkOption {
      type = types.str;
      default = "/dev/vda";
      description = "目标磁盘设备";
    };
  };
  options.rhen.server.ssh.port = mkOption {
    type = types.port;
    default = 22;
    description = "SSH 监听端口";
  };

  config = mkIf cfg.enable {
    disko.devices.disk.main = {
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
              ];
            };
          };
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d /home 0755 root root -"
      "d /var/log 0755 root root -"
      "d /snapshots 0755 root root -"
    ];
    systemd.services.btrfs-setup = {
      description = "Create Btrfs subvolumes";
      wantedBy = [ "multi-user.target" ];
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
      '';
    };
  };
}
