{ lib, config, ... }:
with lib;
let
  cfg = config.rhencloud.impermanence;
in
{
  options.rhencloud.impermanence.enable = mkEnableOption "Impermanence";
  config = mkIf cfg.enable {
    environment.persistence."/persistent" = {
      hideMounts = true;
      directories = [
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/etc/NetworkManager/system-connections"
      ];
      files = [
        "/etc/machine-id"
      ];
      # /home 是独立 btrfs 分区，自然持久化，无需额外配置
    };

    # 注意：当前根分区为 ext4，无法直接设置为只读
    # 要实现真正的 immutable 系统，需要：
    # 1. 将根分区迁移到 btrfs
    # 2. 在 hardware-configuration.nix 中设置：
    #    fileSystems."/" = {
    #      device = "/dev/disk/by-uuid/...";
    #      fsType = "btrfs";
    #      options = [ "subvol=@root" "ro" ];
    #    };
    # 3. 创建 /persistent btrfs 子卷用于持久化数据
    # 4. 在 initrd 中创建临时根文件系统
  };
}
