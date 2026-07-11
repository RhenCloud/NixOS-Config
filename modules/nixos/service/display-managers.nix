{ pkgs, config, ... }:
let
  username = config.rhencloud.primaryUser;
in
{
  # services.desktopManager.plasma6.enable = true;
  services.xserver.desktopManager.runXdgAutostartIfNone = true;
  services.displayManager.sessionPackages = [
    pkgs.hyprland
    pkgs.niri
  ];
  services.displayManager.autoLogin = {
    enable = true;
    user = username;
  };
  services.displayManager = {
    gdm = {
      enable = true;
    };
  };
}
