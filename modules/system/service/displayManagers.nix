{ pkgs, username, ... }:
{
  # services.desktopManager.plasma6.enable = true;
  services.xserver.desktopManager.runXdgAutostartIfNone = true;
  services.displayManager.sessionPackages = [ pkgs.hyprland pkgs.mangowc ];
  services.displayManager.autoLogin = {
    enable = true;
    user = username;
  };
  services.displayManager = {
    gdm = {
      enable = true;
      wayland = true;
    };
  };
}
