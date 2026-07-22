{ pkgs, config, ... }:
let
  username = config.home.username;
in
{
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
}
