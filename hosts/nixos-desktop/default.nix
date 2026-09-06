{ ... }:
{
  # 框架会自动导入 hardware.nix（如果存在）
  # 保留其他必要的配置
  networking.hostName = "nixos-desktop";
  nixpkgs.hostPlatform = "x86_64-linux";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  rhencloud.roles.desktop.enable = true;
}
