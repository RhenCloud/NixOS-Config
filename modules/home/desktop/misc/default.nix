{ pkgs, ... }:
{
  home.packages = with pkgs; [
    chameleon-cli
    # nur.repos.rhencloud.
  ];
}
