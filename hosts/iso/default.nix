# Live CD 配置 — 用于系统迁移和维护
{
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  networking.hostName = "iso";
  nixpkgs.hostPlatform = "x86_64-linux";

  # 基础硬件支持
  boot.supportedFilesystems = [
    "btrfs"
    "ntfs"
    "vfat"
    "ext4"
  ];
  boot.kernelModules = [
    "kvm-intel"
    "ntfs3"
  ];

  # 网络支持
  networking.wireless.enable = true;
  networking.wireless.userControlled = true;

  # 启用常用工具
  environment.systemPackages = with pkgs; [
    btrfs-progs
    rsync
    parted
    gptfdisk
    ntfs3g
    wget
    curl
    git
    vim
    htop
    lsof
    pciutils
    usbutils
    nvme-cli
    smartmontools
  ];

  # ISO 配置
  isoImage = {
    volumeID = "NixOS-RhenCloud";
    squashfsCompression = "zstd -Xcompression-level 22";
    includeSystemBuildDependencies = false;
  };

  # 禁用不必要的服务
  services.xserver.enable = false;
  services.greetd.enable = false;

  # 启用 SSH
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  services.openssh.settings.PasswordAuthentication = true;
}
