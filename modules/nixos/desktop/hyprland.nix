{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.hyprland;
in
{
  options.rhencloud.hyprland.enable = mkEnableOption "Hyprland";

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };
    environment.systemPackages = with pkgs; [
      awww
      # swayosd
      hyprlock
      blueman
      pavucontrol
      # swaynotificationcenter
    ];
  };
}
