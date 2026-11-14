{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhen.xdg;
in
{
  options.rhen.xdg.enable = mkEnableOption "XDG portals configuration";

  config = mkIf cfg.enable {
    xdg = {
      menus.enable = true;
      mime.enable = true;

      portal = {
        enable = true;
        # 注意：不要在这里硬编码 xdg-desktop-portal-hyprland。
        # programs.hyprland 会把重绑定到最终 Hyprland 包的 portalPackage 加入
        # extraPortals；再额外加入未重绑定的原始包会出现两个同名不同 store 路径的
        # 包，导致 systemd user-units 生成时出现
        # `ln: failed to create symbolic link ...xdg-desktop-portal-hyprland.service: File exists`。
        extraPortals = with pkgs; [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-wlr
        ];

        configPackages = [
          pkgs.niri
          pkgs.hyprland
        ];

        config = {
          hyprland = {
            default = [
              "hyprland"
              "gtk"
            ];
            "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          };
          niri = {
            default = [
              "gnome"
              "gtk"
            ];
            "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
            "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
          };
        };

        xdgOpenUsePortal = true;
      };
    };

    environment.etc."xdg/menus/applications.menu".source =
      "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

    environment.pathsToLink = [
      "/share/applications"
      "/share/glib-2.0/schemas"
      "/share/xdg-desktop-portal"
      "/share/zsh"
    ];
  };
}
