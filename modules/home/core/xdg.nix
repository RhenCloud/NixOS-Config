{ config, lib, ... }:
with lib;
let cfg = config.rhencloud.hm-xdg;
in {
  options.rhencloud.hm-xdg.enable = mkEnableOption "XDG user directories";

  config = mkIf cfg.enable {
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      publicShare = "$HOME/Public";
      templates = "$HOME/Templates";
      videos = "$HOME/Videos";
    };

    xresources.properties = {
      "Xcursor.size" = 24;
      "Xft.dpi" = 96;
    };
  };
}
