{ lib, config, ... }:
with lib;
let
  cfg = config.rhencloud.tofi;
in {
  options.rhencloud.tofi.enable = mkEnableOption "Tofi launcher";
  config = mkIf cfg.enable {
    xdg.configFile = {
      "tofi/config" = {
        source = ./config;
      };
    };
    programs.tofi.enable = true;
  };
}
