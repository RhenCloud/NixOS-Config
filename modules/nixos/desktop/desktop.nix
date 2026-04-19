{ pkgs, ... }: {
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    portalPackages = pkgs.xdg-desktop-portal-hyprland;
    xwayland = true;
  };
  environment.systemPackages = with pkgs; [
    swww
    swayosd
    waypaper
    waylyrics
    hyprlock
    hyprcursor
    pyprland
    blueman
    pavucontrol
    hyprpolkitagent
    flameshot
    swaynotificationcenter
    wl-clipboard
    clipse
    kdePackages.dolphin
    hyprswitch
  ];
}
