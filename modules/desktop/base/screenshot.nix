{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.hmScreenshot;
in
{
  options.rhencloud.hmScreenshot.enable = mkEnableOption "screenshot tools";
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
