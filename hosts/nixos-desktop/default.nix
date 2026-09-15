{
  config,
  pkgs,
  ...
}:
{
  # 框架会自动导入 hardware.nix（如果存在）
  # 框架会自动导入 modules/_common/nix/nixos.nix（如果启用了 nix 角色）
  # 框架会自动导入 modules/desktop/roles/nixos.nix（如果启用了 desktop 角色）

  imports = [
    # 框架会自动导入 system/btrfs.nix（如果是 magic 文件）
  ];

  networking.hostName = "nixos-desktop";
  nixpkgs.hostPlatform = "x86_64-linux";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  rhencloud.roles.desktop.enable = true;
}
