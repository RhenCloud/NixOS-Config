{ pkgs, ... }:
{
  home.packages = with pkgs; [
    chameleon-cli
    libreoffice
    wpsoffice-cn
    easytier
    audacity
    kdePackages.kwave
    # twitch
    # nur.repos.rhencloud.
  ];
}
