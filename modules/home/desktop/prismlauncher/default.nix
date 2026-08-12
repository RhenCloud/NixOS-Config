{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.prismlauncher;
  username = config.home.username;
in
{
  options.rhencloud.prismlauncher.enable = mkEnableOption "Prism Launcher";
  config = mkIf cfg.enable {
    programs.prismlauncher = {
      enable = true;

      package = pkgs.prismlauncher.overrideAttrs (oldAttrs: {
        qtWrapperArgs = (oldAttrs.qtWrapperArgs or [ ]) ++ [
          "--set QT_INSTALL_TRANSLATIONS ${pkgs.qt6.qttranslations}/translations"
        ];
      });

      settings = {
        Language = "zh_CN";
        InstanceDir = "/home/${username}/Prism/instances/";
        ApplicationTheme = "dark";
      };
    };
  };
}
