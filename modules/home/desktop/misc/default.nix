{ pkgs, ... }:
{
  home.packages = with pkgs; [
    chameleon-cli
    libreoffice
    wpsoffice-cn
    twitch
    # nur.repos.rhencloud.
  ];
}
