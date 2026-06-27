{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };
  environment.systemPackages = with pkgs; [
    awww
    swayosd
    hyprlock
    blueman
    pavucontrol
    swaynotificationcenter
    # hyprswitch
  ];
}
