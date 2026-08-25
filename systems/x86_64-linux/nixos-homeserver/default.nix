{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    {
      networking.hostName = "nixos-homeserver";
      my.host.name = "nixos-homeserver";
      nixpkgs.hostPlatform = "x86_64-linux";
    }
  ];

  users.users.rhencloud.hashedPassword = lib.mkForce "$y$j9T$F3e7U1XPvw3yEyGE2zERh0$I3/BbHS9YzqcuH1mV8lviQXkNyzF5WPp4wShixIGMX6";

  boot.loader.efi.efiSysMountPoint = lib.mkForce "/boot";
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  services.dbus.implementation = lib.mkForce "broker";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  rhencloud = {
    boot.enable = true;
    identity.enable = true;
    env.enable = true;
    locale.enable = true;
    nix.enable = true;
    packages.enable = true;
    shells.enable = true;

    docker.enable = true;
    podman.enable = true;
    router.enable = true;

    services.beszel-agent.enable = true;
  };
}
