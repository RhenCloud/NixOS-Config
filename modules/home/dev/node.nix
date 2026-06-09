{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs_latest
    nodenv
    pnpm
    wrangler
  ];
  programs.bun = {
    enable = true;
  };
}
