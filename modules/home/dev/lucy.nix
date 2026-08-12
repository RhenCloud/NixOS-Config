{ lib, config, ... }:
with lib;
let
  cfg = config.rhencloud.lucy;
in
{
  options.rhencloud.lucy.enable = mkEnableOption "Lucy CLI tool";
  config = mkIf cfg.enable {
    programs.lucy.enable = true;
  };
}
