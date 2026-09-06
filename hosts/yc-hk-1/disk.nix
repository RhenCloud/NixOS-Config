{ config, lib, inputs, ... }:
with lib;
let
  cfg = config.rhencloud.server.install;
in
{
  imports = [
    inputs.disko.nixosModules.disko
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
                mountOptions = [ "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
