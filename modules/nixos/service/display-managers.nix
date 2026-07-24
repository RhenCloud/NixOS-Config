{ pkgs, primaryUser, ... }: {
  # services.desktopManager.plasma6.enable = true;
  services = {
    xserver.desktopManager.runXdgAutostartIfNone = true;
    displayManager = {
      sessionPackages = [
        pkgs.hyprland
        pkgs.niri
        pkgs.mango
      ];
      autoLogin = {
        enable = true;
        user = primaryUser;
      };
      gdm = {
        enable = true;
      };
    };
  };
}
