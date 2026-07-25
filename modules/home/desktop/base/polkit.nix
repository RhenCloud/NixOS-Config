{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rhencloud.hmPolkit;
in {
  options.rhencloud.hmPolkit.enable = mkEnableOption "Hyprland Polkit agent";
  config = mkIf cfg.enable {
    systemd.user.services.hyprpolkitagent = {
      Unit = {
        Description = "Hyprland Polkit Authentication Agent";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
        Restart = "on-failure";
        RestartSec = 1;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
