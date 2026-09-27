{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.foot;
in
{
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
          alpha = "0.75";
          shell = "${pkgs.fish}/bin/fish";
          selection-target = "clipboard";

          # noctalia 换壁纸时生成的配色（apply.sh 检测到该行已存在便不会再改动本文件）
          include = "${config.xdg.configHome}/foot/themes/noctalia";
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
