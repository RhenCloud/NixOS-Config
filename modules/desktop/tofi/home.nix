{ lib, config, ... }:
with lib;
let
  cfg = config.rhen.tofi;
in
{
  options.rhen.tofi.enable = mkEnableOption "Tofi launcher";
  config = mkIf cfg.enable {
    xdg.configFile = {
      "tofi/config" = {
        source = ./config;
      };
    };
    programs.tofi.enable = true;
  };
}
