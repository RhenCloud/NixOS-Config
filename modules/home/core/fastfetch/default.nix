{ config, lib, ... }:
with lib;
let cfg = config.rhencloud.fastfetch;
in {
  options.rhencloud.fastfetch.enable = mkEnableOption "fastfetch";

  config = mkIf cfg.enable {
    home.file.".config/fastfetch/config.jsonc" = {
      source = ./config.jsonc;
    };
    programs.fastfetch.enable = true;
  };
}
