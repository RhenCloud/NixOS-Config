{ pkgs, primaryUser, ... }: {
  # services.desktopManager.plasma6.enable = true;
  services.xserver.desktopManager.runXdgAutostartIfNone = true;
  services.displayManager.sessionPackages = [
    pkgs.hyprland
    pkgs.niri
    pkgs.mango
  ];
  services.displayManager.autoLogin = {
    enable = true;
    user = primaryUser;
  };
  services.displayManager = {
    gdm = {
      enable = true;
    };
  };
}
