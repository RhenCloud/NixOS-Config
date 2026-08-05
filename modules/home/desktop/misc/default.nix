{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.misc;
in
{
  options.rhencloud.misc.enable = mkEnableOption "miscellaneous desktop apps";

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
      libreoffice
      wpsoffice-cn
      easytier
      audacity
      kdePackages.kwave
      heroic
      # rustdesk
      rustdesk-flutter
    ];
  };
}
