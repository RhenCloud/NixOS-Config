{
  nixos = [
    # core
    "_common.boot"
    "_common.identity"
    "_common.env"
    "_common.fonts"
    "_common.nvidia"
    "_common.locale"
    "_common.nix"
    "_common.fcitx5"
    "_common.packages"
    "_common.services"
    "_common.shells"
    "_common.xdg"

    # desktop
    "desktop.packages"
    "desktop.mangowm"
    "desktop.thunar"
    "desktop.games"
    "desktop.steam"
    "desktop.zen"
    "desktop.sunshine"
    "desktop.avahi"

    # services
    "_common.bluetooth"
    "_common.docker"
    "_common.podman"
    "_common.display-managers"
    "_common.easytier"
    "_common.selector4nix"
    "_common.sound"
    "_common.qemu"
  ];

  home = [
    "desktop.hyprland"
    "desktop.nemo"
    "desktop.umbriel"
  ];
}
