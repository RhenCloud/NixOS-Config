{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.thunar;
in
{
  options.rhencloud.thunar.enable = mkEnableOption "Thunar file manager";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # nufraw-thumbnailer
      ffmpegthumbnailer
    ];

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
