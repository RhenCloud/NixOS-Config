{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    {
      networking.hostName = "nixos-desktop";

      services.gnome.gnome-keyring.enable = true;
      security.pam.services.gdm.enableGnomeKeyring = true;

      nixpkgs.hostPlatform = "x86_64-linux";
    }
  ];
}
