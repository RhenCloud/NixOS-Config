{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    {
      networking.hostName = "nixos-desktop";

      nixpkgs.hostPlatform = "x86_64-linux";
    }
  ];

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  rhencloud.roles.desktop.enable = true;
}
