{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhen.hm-umbriel;
in
{
  options.rhen.hm-umbriel.enable = mkEnableOption "Umbriel (Home Manager)";

  config = mkIf cfg.enable {
    programs.umbriel = {
      enable = true;
      settings = ./umbriel/config.toml;
    };
  };
}
