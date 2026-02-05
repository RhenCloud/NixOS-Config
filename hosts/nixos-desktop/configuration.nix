{ lib, pkgs, stateVersion, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/core
    ../../modules/system/desktop
    ../../modules/system/service
  ];

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;

  system.stateVersion = stateVersion; # 不要改动
}
