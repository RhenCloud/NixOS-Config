{ pkgs, ... }:
{
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

    plymouth = {
      enable = true;
      theme = "nixos-bgrt";
      themePackages = with pkgs; [ nixos-bgrt-plymouth ];
    };

    consoleLogLevel = 3;
    initrd.verbose = false;
    # kernelPackages = pkgs.linuxKernel.kernels.linux_latest;
    # kernelPackages = pkgs.linuxPackages_zen;
    kernelPackages = pkgs.linuxPackages_latest;
    # kernelPackages = pkgs.linuxPackages_6_19;

    # Ensure NVIDIA modules are available early so nvidia-smi and Wayland can initialize cleanly.
    # initrd.kernelModules = [
    #   "nvidia"
    #   "nvidia_modeset"
    #   "nvidia_uvm"
    #   "nvidia_drm"
    # ];
    # kernelModules = [
    #   "nvidia"
    #   "nvidia_modeset"
    #   "nvidia_uvm"
    #   "nvidia_drm"
    # ];
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
  };
}
