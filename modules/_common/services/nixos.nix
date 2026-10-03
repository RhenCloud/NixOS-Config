{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services;
in
{
  options.rhencloud.services.enable = mkEnableOption "system services";

  config = mkIf cfg.enable {
    rhencloud.services.mihomo = {
      enable = true;
      ebpf = true;
    };

    zramSwap.enable = true;

    hardware.gpgSmartcards.enable = true;

    networking = {
      firewall.enable = false;
      networkmanager.enable = true;
    };

    services = {
      mihomo = {
        enable = true;
        configFile = "/etc/mihomo/config.yaml";
        tunMode = true;
        webui = pkgs.metacubexd;
      };
      openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = true;
          KbdInteractiveAuthentication = false;
          MaxAuthTries = 3;
          MaxSessions = 10;
          LoginGraceTime = 30;
        };
      };
      pcscd = {
        enable = true;
        plugins = [ pkgs.ccid ];
      };
      udev.extraRules = ''
        ACTION=="add", SUBSYSTEMS=="usb", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="0030", GROUP="pcscd", MODE="0660", TAG+="uaccess"
      '';
      printing.enable = true;
      udisks2.enable = true;
      dbus = {
        enable = true;
        implementation = "dbus";
      };
    };

    systemd.services.mihomo.serviceConfig = {
      User = "root";
      Group = "root";
      DynamicUser = lib.mkForce false;
      StateDirectory = lib.mkForce "mihomo";
      StateDirectoryMode = lib.mkForce "0755";
    };

    security.polkit.enable = true;

    security.wrappers.pkexec = {
      source = "${lib.getBin pkgs.polkit}/bin/pkexec";
      enable = lib.mkForce true;
      owner = "root";
      group = "root";
      setuid = true;
    };
  };
}
