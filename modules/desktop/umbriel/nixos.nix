{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhencloud.umbriel;
in
{
  options.rhencloud.umbriel.enable = mkEnableOption "Umbriel Wayland 合成器";

  config = mkIf cfg.enable {
    programs.umbriel.enable = true;
  };
}
