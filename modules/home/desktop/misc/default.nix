{ config, lib, pkgs, ... }:
with lib;
let cfg = config.rhencloud.misc;
in {
  options.rhencloud.misc.enable = mkEnableOption "miscellaneous desktop apps";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      chameleon-cli
      libreoffice
      wpsoffice-cn
      easytier
      audacity
      kdePackages.kwave
      heroic
    ];
  };
}
