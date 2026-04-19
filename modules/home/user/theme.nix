{ lib, pkgs, ... }:
{

  home.packages = with pkgs; [
    # catppuccin-cursors
    # catppuccin-fcitx5
    # catppuccin-qt5ct
    # catppuccin-gtk
    # catppuccin-kvantum
    dracula-theme
    dracula-qt5-theme
    papirus-icon-theme

    # libsForQt5.qtstyleplugins
    libsForQt5.qtstyleplugin-kvantum
    libsForQt5.qt5ct
    kdePackages.qt6ct
    kdePackages.qtstyleplugin-kvantum
  ];

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    size = 24;
    package = pkgs.rose-pine-cursor;
    name = "BreezeX-RosePine-Linux";
  };

  qt = {
    enable = true;
    platformTheme.name = lib.mkDefault "gtk3";
    style = {
      package = pkgs.dracula-qt5-theme;
      name = "Dracula";
      # name = "kvantum";
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

  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    GTK_USE_PORTAL = "1";
  };

  xdg.configFile = {
    "kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=Dracula
    '';
  };
}
