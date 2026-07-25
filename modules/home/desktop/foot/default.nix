{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rhencloud.foot;
in {
  options.rhencloud.foot.enable = mkEnableOption "Foot terminal";
  config = mkIf cfg.enable {
    programs.foot = {
      enable = true;

      settings = {
        main = {
          term = "foot";
          font = "Maple Mono NF CN:size=11:fontfeatures=calt=1:fontfeatures=cv03=1:fontfeatures=cv32=1:fontfeatures=cv34=1:fontfeatures=cv35=1:fontfeatures=cv36=1:fontfeatures=cv37=1:fontfeatures=cv96=1:fontfeatures=cv97=1:fontfeatures=cv98=1:fontfeatures=cv99=1:fontfeatures=ss03=1:fontfeatures=ss05=1:fontfeatures=zero=1";
          dpi-aware = "yes";
          pad = "8x8 center";
          shell = "${pkgs.fish}/bin/fish";
          selection-target = "clipboard";
        };

        colors-dark = {
          alpha = "0.75";
          background = "282a36";
          foreground = "f8f8f2";
          regular0 = "44475a";
          regular1 = "ff5555";
          regular2 = "50fa7b";
          regular3 = "f1fa8c";
          regular4 = "bd93f9";
          regular5 = "ff79c6";
          regular6 = "8be9fd";
          regular7 = "f8f8f2";
          bright0 = "6272a4";
          bright1 = "ff6e6e";
          bright2 = "69ff94";
          bright3 = "ffffa5";
          bright4 = "d6acff";
          bright5 = "ff92df";
          bright6 = "a4ffff";
          bright7 = "ffffff";
          cursor = "f8f8f2 44475a";
          selection-foreground = "f8f8f2";
          selection-background = "44475a";
        };

        cursor = {
          style = "beam";
        };

        mouse = {
          hide-when-typing = "yes";
        };

        bell = {
          urgent = "no";
          notify = "no";
        };

        scrollback = {
          lines = 10000;
          indicator-position = "none";
        };

        url = {
          launch = "${pkgs.xdg-utils}/bin/xdg-open";
          osc8-underline = "always";
          label-letters = "sdfjklgh";
        };
      };
    };
  };
}
