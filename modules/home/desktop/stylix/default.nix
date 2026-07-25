{ lib, config, ... }:
with lib;
let
  cfg = config.rhencloud.hmStylix;
in {
  options.rhencloud.hmStylix.enable = mkEnableOption "HM Stylix theme";
  config = mkIf cfg.enable { };
}
