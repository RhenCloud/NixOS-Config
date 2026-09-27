{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.theme;

  accent = "pink";
  variant = "mocha";

  kvantumThemePackage = pkgs.catppuccin-kvantum.override { inherit variant accent; };
  themeName = "catppuccin-${variant}-${accent}";
in
{
  options.rhencloud.theme.enable = mkEnableOption "desktop theme (GTK/Qt)";

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        catppuccin-kvantum
        adw-gtk3
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
        GTK_USE_PORTAL = "1";
        QT_STYLE_OVERRIDE = "kvantum";
        GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/glib-2.0/schemas";
      };
    };

    qt = {
      enable = true;
      style = {
        package = pkgs.libsForQt5.qtstyleplugin-kvantum;
        name = "kvantum";
      };
    };

    gtk = {
      enable = true;
      # 全局界面字体（gtk2/gtk3/gtk4 继承）
      font = {
        name = "Maple Mono NF CN";
        size = 11;
      };
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      # noctalia 生成的调色板，换壁纸时自动重写同目录下的 noctalia.css
      gtk3.extraCss = ''@import url("noctalia.css");'';
      gtk4 = {
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        extraCss = ''@import url("noctalia.css");'';
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
