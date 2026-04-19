{ pkgs, ... }:
{
  home.packages = with pkgs; [
    python315
    # python311
  ];
  programs.uv = {
    enable = true;
  };
}
