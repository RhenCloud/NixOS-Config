{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.bluetooth;

  btIsoEnable = pkgs.callPackage ../../../packages/bt-iso-enable {
    kernel = config.boot.kernelPackages.kernel;
  };
in
{
  options.rhencloud.bluetooth.enable = mkEnableOption "Bluetooth";

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };
    services.blueman.enable = true;

    boot.extraModulePackages = [ btIsoEnable ];

    systemd.services = {
      bt-iso-enable = {
        description = "Load bt-iso-enable kernel module for Bluetooth ISO socket support";
        before = [ "bluetooth.service" ];
        wantedBy = [ "bluetooth.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.kmod}/bin/modprobe bt-iso-enable";
        };
      };
      bluetooth-unblock = {
        description = "Unblock and power on Bluetooth adapter";
        after = [ "bluetooth.service" ];
        wants = [ "bluetooth.service" ];
        wantedBy = [ "bluetooth.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "bluetooth-unblock" ''
            ${pkgs.util-linux}/bin/rfkill unblock bluetooth
            sleep 1
            ${pkgs.bluez}/bin/bluetoothctl power on
          '';
        };
      };
    };

    environment.systemPackages = with pkgs; [
      bluez
      bluez-tools
    ];
  };
}
