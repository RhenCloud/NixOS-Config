{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhen.umbriel;
in
{
  options.rhen.umbriel.enable = mkEnableOption "Umbriel Wayland 合成器";

  config = mkIf cfg.enable {
    programs.umbriel.enable = true;
  };
}
