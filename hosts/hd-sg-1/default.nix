{
  config,
  lib,
  snowveil,
  ...
}:
{
  networking.hostName = "hd-sg-1";
  networking.domain = "rhen.cloud";
  nixpkgs.hostPlatform = "x86_64-linux";

  # 安装后由主机 SSH key 解密本机 secrets；安装阶段使用临时 SSH key。
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  rhen.server.install = {
    enable = true;
    disk = "/dev/sda";
  };
  rhen.server.ssh.port = 22222;

  networking = {
    useNetworkd = true;
    useDHCP = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22222 ];
    };
  };

  systemd.network.wait-online.enable = false;

  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };
  boot.initrd.kernelModules = [
    "virtio_blk"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
  ];

  services.openssh = {
    enable = true;
    ports = [ 22222 ];
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  # 首次安装必须保证 root 与主用户都有可用的管理 key。
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPuthZJ1ELm9QFDDUWBfzdfRZk5JE9iHOLWjU+QQTQbE cardno:FFFE_E046F201"
  ];
  users.users.rhencloud.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPuthZJ1ELm9QFDDUWBfzdfRZk5JE9iHOLWjU+QQTQbE cardno:FFFE_E046F201"
  ];

  zramSwap.enable = true;

  # 最小 server 不主动启用业务服务；后续服务应在此主机专属模块中加入。
  # server 公共聚合器默认开启 Cloudflare Tunnel；新主机暂不挂载 yc-hk-1 的 tunnel secret。
  rhen.cloudflared.enable = lib.mkForce false;

  rhen.services = {
    mihomo.enable = false;
    baota-probe.enable = false;
    nextbridge.enable = false;
    frp.enable = false;
    easytier.enable = false;
    vaultwarden.enable = false;
    sleepy.enable = false;
    mailer.enable = false;
    wyf9s-bot.enable = false;
    gost.enable = false;
    rustdesk.enable = false;
    openlist.enable = false;
    oci-helper.enable = false;
    pds.enable = false;
    beszel-agent.enable = false;
  };
}
