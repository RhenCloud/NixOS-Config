{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  hostName = "yc-hk-1";
in
{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko-config.nix
  ];

  networking.hostName = hostName;
  my.host.name = hostName;
  my.homeManager.enable = false;
  nixpkgs.hostPlatform = "x86_64-linux";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  rhencloud.server.install.enable = true;

  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };

  boot.initrd.kernelModules = [
    "virtio_blk"
    "virtio_pci"
  ];

  networking = {
    useNetworkd = true;
    firewall.enable = false;
  };

  systemd.network.wait-online.enable = false;

  systemd.network.networks."50-ens17" = {
    matchConfig.Name = "ens*";
    address = [ "83.229.127.169/24" ];
    gateway = [ "83.229.127.254" ];
    dns = [
      "172.16.36.100"
      "172.16.36.101"
    ];
    networkConfig.DHCP = "no";
  };

  environment.systemPackages = with pkgs; [
    python3
    uv
  ];

  services.openssh = {
    enable = true;
    ports = [ config.rhencloud.server.ssh.port ];
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  virtualisation.podman.dockerCompat = true;

  rhencloud = {
    identity.enable = true;
    locale.enable = true;
    nix.enable = true;
    packages.enable = true;
    shells.enable = true;
    cloudflared.enable = true;
    services.nextbridge.enable = true;
    services.frp.enable = true;
    services.easytier.enable = true;
    services.vaultwarden.enable = true;
    services.sleepy.enable = true;
    services.mailer.enable = true;
    services.wyf9s-bot.enable = true;
    services.gost.enable = true;
    services.rustdesk.enable = true;
    services.postgresql = {
      enable = true;
      databases = [
        {
          name = "nextbridge";
          user = "nextbridge";
          passwordSecret = "postgres-nextbridge-password";
        }
      ];
    };
  };

  users.users = {
    rhencloud.openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+/7cpkWShU8aEDBq2StSJRSeVbFvj8BSEP85HEEtYZ i@rhen.cloud"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPuthZJ1ELm9QFDDUWBfzdfRZk5JE9iHOLWjU+QQTQbE cardno:FFFE_E046F201"
    ];
    wyf9 = {
      isNormalUser = true;
      group = "wyf9";
      shell = pkgs.bash;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFIma5iDdPnEdjYbj7epS/ogQaJmWAvWm8jnXgvU10x wyf9@wyf9Desktop"
      ];
    };
    root = {
      initialPassword = "nixos";
      openssh.authorizedKeys.keys = [
        # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+/7cpkWShU8aEDBq2StSJRSeVbFvj8BSEP85HEEtYZ i@rhen.cloud"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPuthZJ1ELm9QFDDUWBfzdfRZk5JE9iHOLWjU+QQTQbE cardno:FFFE_E046F201"
      ];
    };
  };

  users.groups.wyf9 = { };
}
