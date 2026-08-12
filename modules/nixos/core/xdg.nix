{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.xdg;
in
{
  options.rhencloud.xdg.enable = mkEnableOption "XDG portals configuration";

  config = mkIf cfg.enable {
    xdg = {
      menus.enable = true;
      mime.enable = true;

      portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-hyprland
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
            "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
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
