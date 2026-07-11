{ pkgs, ... }:
{
  home.packages = with pkgs; [
    awww
    waypaper
    # dms-shell
    # linux-wallpaperengine
    waylyrics
    hyprpolkitagent
    clipse
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.kservice
    shared-mime-info
    xdg-utils

    slurp
    grim
    satty
    shutter

    playerctl

    wl-clipboard
    cliphist
    copyq
    nwg-clipman

    krita
    kdePackages.gwenview

    hyfetch

    # thunar
    # thunar-volman
    # thunar-vcs-plugin
    # thunar-archive-plugin
    # thunar-media-tags-plugin
    # gvfs
    kdePackages.ark
    rar

    localsend

    splayer
  ];
}
