{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhencloud.hm-umbriel;
in
{
  options.rhencloud.hm-umbriel.enable = mkEnableOption "Umbriel (Home Manager)";

  config = mkIf cfg.enable {
    programs.umbriel = {
      enable = true;
      settings = ./umbriel/config.toml;
    };
  };
}
