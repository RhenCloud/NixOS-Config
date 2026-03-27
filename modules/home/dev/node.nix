{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs_25
    nodenv
    pnpm
  ];
  programs.bun = {
    enable = true;
  };
}
