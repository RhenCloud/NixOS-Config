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

  # 仅保留可用的镜像源；失效源会导致 podman 拉取时挂起点。
  environment.etc."containers/registries.conf.d/50-mirrors.conf".text = ''
    [[registry]]
    location = "docker.io"
    [[registry.mirror]]
    location = "docker.1ms.run"
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
    router.enable = false;

    services.beszel-agent.enable = false;
    services.baota-probe.enable = true;
    services.mihomo-router.enable = false;

    services.pds = {
      enable = true;
      role = "server";
    };

    services.snowluma = {
      enable = true;
    };

    # OpenList 与 aria2 必须同机（官方限制：离线下载不能跨设备），
    # 因此下载器与 OpenList 都放在本机，下载数据落在 /Data2。
    # OpenList 与 aria2 已停用：Google Drive 等存储需要访问 Google，
    # 家庭网络无法直连，对外服务统一由 yc-hk-1 提供（olist.rhen.cloud）。
    # 数据（/var/lib/openlist）与下载目录（/Data2/openlist-*）均保留，以后可重新启用。
    services.openlist.enable = false;
    services.aria2.enable = false;

    # 经 frps 保留 SSH 回程隧道：内网机器被 NAT 挡住时可用 yc-hk-1:2222 登录本机
    services.frpc = {
      enable = true;
      proxies = [
        {
          name = "ssh";
          localPort = 22;
          remotePort = 2222;
        }
      ];
    };

    # 让本机作为接入点，其他设备连入后可经 enp3s0 上行上网。
    services.wifiAp = {
      enable = true;
      interface = "wlp1s0";
      upstreamInterface = "enp3s0";
      ssid = "Rhen-HomeServer";
    };
  };

  # 直接通过家庭路由器接入局域网，不再由本机承担软路由和桥接职责。
  # 普通家庭局域网模式：由 NetworkManager 管理物理网卡并通过 DHCP 获取地址。
  networking.useNetworkd = lib.mkForce false;
  networking.networkmanager.enable = lib.mkForce true;
  networking.useDHCP = lib.mkForce true;

  # 关闭 router 角色后不再由 router/services 模块隐式启用 SSH，显式声明 SSH 服务。
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # 镜像源（docker.1ms.run）在 tag 校验或大层拉取时会挂起，
  # 而激活阶段卡在容器启动会直接导致 deploy-rs 超时回滚。
  # 因此统一改为仅在镜像缺失时拉取；需要升级镜像时手动 podman pull 后重启对应服务。
  virtualisation.oci-containers.containers = {
    postgresql.pull = lib.mkForce "missing";
    bsky-pds.pull = lib.mkForce "missing";
    snowluma.pull = lib.mkForce "missing";
    bt-probe-agent.pull = lib.mkForce "missing";
  };
}
