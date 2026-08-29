{ pkgs, ... }:
# nixos-shell 测试用配置：根文件系统为 tmpfs，重启即失
# 用法：nix run .#vm [可选配置文件路径]
{
  services.getty.autologinUser = "root";

  environment.systemPackages = with pkgs; [
    vim
    git
    nixos-shell
    bashInteractive
  ];

  # VM 内启用 nix 命令（如需联网构建 / 测试）
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  virtualisation.writableStore = true;
  virtualisation.memorySize = 2048;
  virtualisation.cores = 2;
}