{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.displayManagers;

  sessionsDir = pkgs.symlinkJoin {
    name = "greetd-sessions";
    paths =
      let
        mkSession =
          {
            name,
            desktopName,
            exec,
            comment ? "",
          }:
          pkgs.makeDesktopItem {
            inherit
              name
              desktopName
              exec
              comment
              ;
            categories = [
              "GNOME"
              "GTK"
            ];
            type = "Application";
          };
      in
      with pkgs;
      [
        (mkSession {
          name = "niri";
          desktopName = "Niri";
          exec = "${niri}/bin/niri-session";
        })
        (mkSession {
          name = "hyprland";
          desktopName = "Hyprland";
          exec = "${hyprland}/bin/Hyprland";
        })
        (mkSession {
          name = "mango";
          desktopName = "Mango";
          exec = "${pkgs.mango}/bin/mango";
        })
      ];
  };
in
{
  options.rhencloud.displayManagers.enable = mkEnableOption "display manager";

  config = mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --sessions ${sessionsDir}/share/applications";
          user = "greeter";
        };
      };
    };

    systemd.services.greetd = {
      wants = [ "plymouth-quit.service" ];
      after = [ "plymouth-quit.service" ];
    };
  };
}
