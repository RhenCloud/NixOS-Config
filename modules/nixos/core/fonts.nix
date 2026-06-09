{ pkgs, ... }:
{
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

    # 设置 fontconfig 防止出现乱码
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
    };
  };
}
