{ pkgs, ... }:
{
  home.packages = with pkgs; [
    chameleon-cli
    libreoffice
    wpsoffice-cn
    # nur.repos.rhencloud.
  ];
}
