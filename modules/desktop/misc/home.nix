{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhen.misc;
in
{
  options.rhen.misc.enable = mkEnableOption "miscellaneous desktop apps";

  config = mkIf cfg.enable {
    programs.fish.functions.rustdesk = {
      body = ''
        set -gx GDK_BACKEND x11
        command rustdesk $argv
        set -e GDK_BACKEND
      '';
    };

    home.packages = with pkgs; [
      chameleon-cli
      # libreoffice
      wpsoffice-cn
      easytier
      # audacity
      kdePackages.kwave
      heroic
      lutris
      # rustdesk
      rustdesk-flutter
      inkscape
      figma-linux
      ventoy-full-qt
    ];
  };
}
