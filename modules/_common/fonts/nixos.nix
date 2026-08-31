{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.fonts;
in
{
  options.rhencloud.fonts.enable = mkEnableOption "fonts configuration";

  config = mkIf cfg.enable {
    fonts = {
      fontDir.enable = true;
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        source-code-pro
        source-han-sans
        source-han-serif
        sarasa-gothic
        maple-mono.NF-CN-unhinted
        maple-mono.truetype
      ];

      fontconfig = {
        defaultFonts = {
          emoji = [ "Noto Color Emoji" ];
          monospace = [
            "Maple Mono NF CN"
            "Noto Sans Mono CJK SC"
            "Sarasa Mono SC"
            "DejaVu Sans Mono"
          ];
          sansSerif = [
            "Maple Mono NF CN"
            "Noto Sans CJK SC"
            "Source Han Sans SC"
            "DejaVu Sans"
          ];
          serif = [
            "Noto Serif CJK SC"
            "Source Han Serif SC"
            "DejaVu Serif"
          ];
        };
        localConf = ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <alias>
              <family>Microsoft YaHei</family>
              <prefer><family>sans-serif</family></prefer>
            </alias>
            <alias>
              <family>Microsoft YaHei UI</family>
              <prefer><family>sans-serif</family></prefer>
            </alias>
            <alias>
              <family>Microsoft JhengHei</family>
              <prefer><family>sans-serif</family></prefer>
            </alias>
            <alias>
              <family>Microsoft JhengHei UI</family>
              <prefer><family>sans-serif</family></prefer>
            </alias>
            <alias>
              <family>SimHei</family>
              <prefer><family>sans-serif</family></prefer>
            </alias>
            <alias>
              <family>DengXian</family>
              <prefer><family>sans-serif</family></prefer>
            </alias>
            <alias>
              <family>SimSun</family>
              <prefer><family>serif</family></prefer>
            </alias>
            <alias>
              <family>NSimSun</family>
              <prefer><family>serif</family></prefer>
            </alias>
            <alias>
              <family>FangSong</family>
              <prefer><family>serif</family></prefer>
            </alias>
            <alias>
              <family>KaiTi</family>
              <prefer><family>serif</family></prefer>
            </alias>
          </fontconfig>
        '';
      };
    };
  };
}
