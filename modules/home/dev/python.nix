{ pkgs, ... }:
{
  home.packages = with pkgs; [
    python315
  ];
  programs.uv = {
    enable = true;
  };
}
