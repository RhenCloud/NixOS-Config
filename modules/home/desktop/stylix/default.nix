{ pkgs, ... }:

{
  stylix.enable = true;
  stylix = {
    fonts = {
      serif = {
        package = pkgs.maple-mono.NF-CN;
        name = "Maple Mono NF CN";
      };

      sansSerif = {
        package = pkgs.maple-mono.NF-CN;
        name = "Maple Mono NF CN";
      };

      monospace = {
        package = pkgs.maple-mono.NF-CN;
        name = "Maple Mono NF CN";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}
