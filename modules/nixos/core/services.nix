{
  pkgs,
  lib,
  config,
  ...
}:
let
  username = config.rhencloud.primaryUser;
in
{
  zramSwap.enable = true;

  networking = {
    firewall.enable = false;
    networkmanager.enable = true;
  };

  services.mihomo = {
    enable = true;
    configFile = "/etc/mihomo/config.yaml";
    tunMode = true;
    webui = pkgs.metacubexd;
  };

  systemd.services.mihomo.serviceConfig = {
    ExecStart = lib.mkForce ''
      ${pkgs.mihomo}/bin/mihomo -d /var/lib/mihomo -f ${config.services.mihomo.configFile}
    '';
    User = lib.mkForce username;
    Group = lib.mkForce username;
    DynamicUser = lib.mkForce false;
    StateDirectory = lib.mkForce "mihomo";
    StateDirectoryMode = lib.mkForce "0755";
  };

  services.dae = {
    enable = false;
    configFile = "/etc/dae/config.dae";
    assets = with pkgs; [
      v2ray-geoip
      v2ray-domain-list-community
    ];
    openFirewall = {
      enable = true;
      port = 1536;
    };
  };

  environment.etc = {
    "dae/config.dae".source = ./dae/config.dae;
    "dae/nodes.dae".source = ./dae/nodes.dae;
  };

  services.openssh.enable = true;
  services.pcscd.enable = true;
  services.pcscd.plugins = [ pkgs.ccid ];
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEMS=="usb", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="0030", GROUP="pcscd", MODE="0660", TAG+="uaccess"
  '';

  # 启用 CUPS 打印支持
  services.printing.enable = true;

  services.udisks2.enable = true;
  services.dbus = {
    enable = true;
    implementation = "dbus";
  };
  security.polkit.enable = true;

  security.wrappers.pkexec = {
    source = "${lib.getBin pkgs.polkit}/bin/pkexec";
    enable = lib.mkForce true;
    owner = "root";
    group = "root";
    setuid = true;
  };
}
