{ config, lib, ... }:
with lib;
let
  cfg = config.rhencloud.roles.desktop;
in
{
  options.rhencloud.roles.desktop = {
    enable = mkEnableOption "桌面角色（图形环境、桌面应用与游戏）";
  };

  config = mkIf cfg.enable {
    my.isDesktop = true;

    rhencloud = {
      # core
      boot.enable = true;
      identity.enable = true;
      env.enable = true;
      fonts.enable = true;
      nvidia.enable = true;
      locale.enable = true;
      nix.enable = true;
      fcitx5.enable = true;
      packages.enable = true;
      services.enable = true;
      shells.enable = true;
      xdg.enable = true;

      # desktop
      desktopPackages.enable = true;
      hyprland.enable = true;
      mangowm.enable = true;
      thunar.enable = true;
      games.enable = true;
      steam.enable = true;
      zen.enable = true;
      sunshine.enable = true;
      avahi.enable = true;

      # service
      bluetooth.enable = true;
      docker.enable = true;
      displayManagers.enable = true;
      easytier.enable = true;
      selector4nix.enable = true;
      sound.enable = true;
      qemu.enable = true;
    };
  };
}
