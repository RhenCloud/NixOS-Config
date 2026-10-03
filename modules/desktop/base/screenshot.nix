{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhen.hmScreenshot;
in
{
  options.rhen.hmScreenshot.enable = mkEnableOption "screenshot tools";
  config = mkIf cfg.enable {
    services.flameshot = {
      enable = true;
      package = pkgs.flameshot.override { enableWlrSupport = true; };
      settings = {
        General = {
          useGrimAdapter = true;
          showDesktopNotification = false;
          showStartupLaunchMessage = false;
        };
      };
    };

    programs.satty = {
      enable = true;
      settings = {
        general = {
          output-filename = "~/Pictures/Screenshots/Screenshot-%Y-%m-%d_%H:%M:%S.png";
        };
      };
    };
  };
}
