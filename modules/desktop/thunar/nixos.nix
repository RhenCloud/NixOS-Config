{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhen.thunar;
in
{
  options.rhen.thunar = {
    enable = mkEnableOption "Thunar file manager";
  };

  config = mkIf cfg.enable {
    programs = {
      thunar = {
        plugins = with pkgs; [
          thunar-volman
          thunar-vcs-plugin
          thunar-archive-plugin
          thunar-media-tags-plugin
        ];
        enable = true;
      };
      xfconf.enable = true;
    };

    services.gvfs.enable = true;
    services.tumbler.enable = true;
  };
}
