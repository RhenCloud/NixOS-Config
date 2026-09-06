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
  options.rhencloud.thunar = {
    enable = mkEnableOption "Thunar file manager";
    enableNemo = mkOption {
      type = types.bool;
      default = true;
      description = "Also enable Nemo file manager (Cinnamon desktop)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      (with pkgs; [
        ffmpegthumbnailer
      ])
      ++ (optionals cfg.enableNemo (
        with pkgs;
        [
          nemo
          nemo-fileroller
          nemo-preview
          nemo-seahorse
          nemo-python
          nemo-emblems
        ]
      ));

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
