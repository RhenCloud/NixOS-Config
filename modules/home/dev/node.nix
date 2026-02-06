{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs_25
    nodenv
  ];
  programs.bun = {
    enable = true;
  };
}
