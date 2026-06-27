{ pkgs, ... }:

{
  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  hardware.bluetooth.settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
      Experimental = true;
    };
  };

  # rfkill 导致蓝牙被 soft-blocked，启动后强制 unblock 并重新供电
  systemd.services.bluetooth-unblock = {
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

  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
  ];
}
