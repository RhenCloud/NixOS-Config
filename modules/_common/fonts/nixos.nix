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
            <!-- 彩色 emoji 优先。
                 实测回退链为 Noto Sans Symbols 2 -> Unifont Upper -> Noto Color Emoji，
                 前两者是单色线条/位图字体，Chromium/CEF（微信、Electron 应用）据此
                 选中它们，emoji 就会显示成单色轮廓或豆腐块。

                 但 Noto Color Emoji 同时声明覆盖 U+0030-U+0039（其 keycap 由
                 「数字 + U+20E3」经 GSUB 合成），所以不能简单地把它整体提到最前，
                 否则所有阿拉伯数字都会被渲染成 emoji。这里分两步：
                 1. 强制把正文字体 Maple Mono NF CN 置顶，凡它有字形的码位（数字、
                    拉丁、中文）一律由它渲染；
                 2. 再用 prefer 让 Noto Color Emoji 排在 Noto Sans Symbols 2 /
                    Unifont 之前，接管剩余的 emoji 码位。 -->
            <match target="pattern">
              <edit name="family" mode="prepend" binding="strong">
                <string>Maple Mono NF CN</string>
              </edit>
            </match>
            <alias binding="same">
              <family>sans-serif</family>
              <prefer>
                <family>Maple Mono NF CN</family>
                <family>Noto Color Emoji</family>
              </prefer>
            </alias>
          </fontconfig>
        '';
      };
    };
  };
}
