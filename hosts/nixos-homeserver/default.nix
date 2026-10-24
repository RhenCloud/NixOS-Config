{
  snowveil,
  config,
  lib,
  ...
}:
{
  # 框架会自动导入 hardware.nix（如果存在）
  networking.hostName = "nixos-homeserver";
  nixpkgs.hostPlatform = "x86_64-linux";

  # 此主机使用独立密码哈希；覆盖 identity 模块默认的 common 密钥来源。
  sops.secrets."password-hash" =
    snowveil.sops.secret {
      source = "host";
      host = "nixos-homeserver";
    }
    // {
      neededForUsers = true;
    };

  boot.loader.efi.efiSysMountPoint = lib.mkForce "/boot";
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  services.dbus.implementation = lib.mkForce "broker";

  environment.etc."containers/registries.conf.d/50-mirrors.conf".text = ''
    [[registry]]
    location = "docker.io"
    [[registry.mirror]]
    location = "docker.1ms.run"
    [[registry.mirror]]
    location = "docker.cattt.net"
  '';

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  rhen = {
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

    services.beszel-agent.enable = false;
    services.baota-probe.enable = true;
    services.mihomo-router.enable = false;

    services.pds = {
      enable = true;
      role = "server";
    };
  };
}
