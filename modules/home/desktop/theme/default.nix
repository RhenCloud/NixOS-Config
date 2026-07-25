{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.rhencloud.theme;

  accent = "pink";
  variant = "mocha";

  kvantumThemePackage = pkgs.catppuccin-kvantum.override { inherit variant accent; };
  themeName = "catppuccin-${variant}-${accent}";
in {
  options.rhencloud.theme.enable = mkEnableOption "desktop theme (GTK/Qt)";

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        dracula-theme
        catppuccin-kvantum
        papirus-icon-theme
        libsForQt5.qtstyleplugin-kvantum
        libsForQt5.qt5ct
        kdePackages.qt6ct
        kdePackages.qtstyleplugin-kvantum
      ];
      pointerCursor = {
        enable = true;
        gtk.enable = true;
        x11.enable = true;
        size = 24;
        package = pkgs.rose-pine-cursor;
        name = "BreezeX-RosePine-Linux";
      };
      sessionVariables = {
        XDG_CURRENT_DESKTOP = "Hyprland";
        GTK_USE_PORTAL = "1";
        QT_QPA_PLATFORMTHEME = lib.mkForce "gtk3";
        QT_STYLE_OVERRIDE = "kvantum";
        GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/glib-2.0/schemas";
      };
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk3";
      style = {
        package = pkgs.libsForQt5.qtstyleplugin-kvantum;
        name = "kvantum";
      };
    };

    gtk = {
      enable = true;
      font = {
        name = "Maple Mono NF CN";
        size = 12;
      };
      theme = {
        name = "Dracula";
        package = pkgs.dracula-theme;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
    };

    xdg.configFile = {
      "Kvantum/kvantum.kvconfig".text = ''
        [General]
        theme=${themeName}
      '';

      "Kvantum/${themeName}".source = "${kvantumThemePackage}/share/Kvantum/${themeName}";
    };
  };
}
