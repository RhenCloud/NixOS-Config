{
  cloud,
  config,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    {
      networking.hostName = "nixos-homeserver";
      my.host.name = "nixos-homeserver";
      nixpkgs.hostPlatform = "x86_64-linux";
    }
  ];

  # 此主机使用独立密码哈希；覆盖 identity 模块默认的 common 密钥来源。
  sops.secrets."password-hash" = lib.mkForce (
    cloud.sops.secret {
      source = "host";
      host = "nixos-homeserver";
    }
    // {
      neededForUsers = true;
    }
  );
  users.users.rhencloud.hashedPasswordFile = lib.mkForce config.sops.secrets."password-hash".path;

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
    services.baota-probe.enable = true;

    services.pds = {
      enable = true;
      role = "server";
    };
  };
}
