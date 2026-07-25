{ config, lib, pkgs, primaryUser, ... }:
with lib;
let cfg = config.rhencloud.displayManagers;
in {
  options.rhencloud.displayManagers.enable = mkEnableOption "display manager (GDM)";

  config = mkIf cfg.enable {
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
  };
}
