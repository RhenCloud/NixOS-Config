{ lib, config, ... }:
with lib;
let
  cfg = config.rhen.lucy;
in
{
  options.rhen.lucy.enable = mkEnableOption "Lucy CLI tool";
  config = mkIf cfg.enable {
    programs.lucy.enable = true;
  };
}
