{ pkgs, ... }:
{
  home.packages = with pkgs; [
    python315
    prek
    ruff
    # python311
  ];

  nixpkgs.config.allowInsecure = true;

  programs.uv = {
    enable = true;
  };
}
