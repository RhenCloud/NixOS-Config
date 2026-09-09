{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.nemo;
in
{
  options.rhencloud.nemo = {
    enable = mkEnableOption "Nemo file manager";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.nemo-with-extensions
      pkgs.ffmpegthumbnailer
    ];
  };
}
