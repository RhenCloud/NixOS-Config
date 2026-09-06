{
  pkgs,
  inputs,
  ...
}:
let
  hostName = "yc-hk-1";
in
{
  # 框架会自动导入 disk.nix（包含 disko 模块和配置）
  imports = [
    ({ config, ... }: {
      services.openssh.ports = [ config.rhencloud.server.ssh.port ];
    })
  ];

  networking.hostName = hostName;
  my.host.name = hostName;
  my.homeManager.enable = false;

  nixpkgs.hostPlatform = "x86_64-linux";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  rhencloud.roles.server.enable = true;

  rhencloud.server.install.enable = true;

  rhencloud.services = {
    beszel.enable = true;
    nextbridge.enable = true;
    frp.enable = true;
    easytier.enable = true;
    vaultwarden.enable = true;
    sleepy.enable = true;
    mailer.enable = true;
    wyf9s-bot.enable = true;
    gost.enable = true;
    rustdesk.enable = true;
    yysong.enable = true;

    pds = {
      enable = true;
      role = "proxy";
    };
  };

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

  rhencloud.services.postgresql = {
    databases = [
      {
        name = "nextbridge";
        user = "nextbridge";
        passwordSecret = "postgres-nextbridge-password";
      }
      {
        name = "yysong";
        user = "yysong";
        passwordSecret = "postgres-yysong-password";
      }
    ];
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
    advan10 = {
      isNormalUser = true;
      group = "advan10";
      shell = pkgs.bash;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPr3U8DY69/23U+j7Y8/BdPJsGBdgufymLzZEER0/2AA advan10@siiway.org"
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

  users.groups = {
    wyf9 = { };
    advan10 = { };
  };
}
