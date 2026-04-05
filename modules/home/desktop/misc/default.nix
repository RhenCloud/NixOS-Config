{ pkgs, ... }:
{
  home.packages = with pkgs; [
    chameleon-cli
  ];
}
