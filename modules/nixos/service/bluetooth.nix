{ config, pkgs, ... }:

let
  btIsoEnable = pkgs.callPackage ../../../packages/bt-iso-enable {
    kernel = config.boot.kernelPackages.kernel;
  };
in

{
  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # bt-iso-enable: 内核模块，通过 kprobe 调用 iso_init() 以注册 Bluetooth ISO 协议。
  # 这是内核 bug 的 workaround：bt_init() 遗漏了 iso_init() 调用。
  # 注意：不加入 boot.kernelModules 因为 bluetooth.ko 此时尚未加载（iso_init
  # 符号不存在）。改用 systemd service 在 bluetooth.service 后加载。
  boot.extraModulePackages = [ btIsoEnable ];

  systemd.services.bt-iso-enable = {
    description = "Load bt-iso-enable kernel module for Bluetooth ISO socket support";
    before = [ "bluetooth.service" ];
    wantedBy = [ "bluetooth.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.kmod}/bin/modprobe bt-iso-enable";
    };
  };

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
