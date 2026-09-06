# rhencloud 用户的共享 home-manager 配置
# 此配置生成 homeConfigurations.rhencloud，被所有关联的 per-host 配置继承
{ config, lib, ... }:
{
  home.stateVersion = lib.mkDefault "26.11";
  programs.home-manager.enable = true;
  programs.man.enable = false;

  # 共享的模块启用配置
  # 不同主机可在各自的 nixos-desktop.nix 等文件中覆盖或补充
  rhencloud = {
    # 所有主机都启用的基础模块
    git.enable = true;
    fish.enable = true;
    fastfetch.enable = true;

    # 可由 per-host 配置覆盖的默认值
    herdr.enable = lib.mkDefault true;
  };
}
