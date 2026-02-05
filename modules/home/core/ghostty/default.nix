{ ... }:
{
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    systemd.enable = true;
    settings = {
      font-family = "Maple Mono NF CN";
      font-feature = "zero,cv03,ss03,ss05,cv97,cv98";
      font-size = 11.0;
      theme = "Dracula";
      cursor-style = "bar";
      background-opacity = 0.75;
      clipboard-read = "allow";
      clipboard-write = "allow";
      bell-features = "title,no-audio,no-system,no-attention";
    };
  };
}
