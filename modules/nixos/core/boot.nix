{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rhencloud.boot;
in {
  options.rhencloud.boot.enable = mkEnableOption "boot configuration";
  config = mkIf cfg.enable {
    boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 1048576;
    "fs.inotify.max_user_instances" = 1024;
    "fs.inotify.max_queued_events" = 1048576;
  };
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = false;
        gfxmodeEfi = "1920x1080";
      };

      systemd-boot = {
        enable = false;
      };

      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };

    plymouth.enable = false;

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "boot.shell_on_fail"
    ];
  };
  };
}
