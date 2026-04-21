{ pkgs, ... }:
{
  home.packages = with pkgs; [
    python315
    prek
    ruff
    olm
    # python311
  ];

  nixpkgs.config.allowInsecure = true;

  programs.uv = {
    enable = true;
  };
}
