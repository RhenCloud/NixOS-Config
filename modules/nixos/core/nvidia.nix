{ config, lib, ... }:
with lib;
let
  cfg = config.rhencloud.nvidia;
in
{
  options.rhencloud.nvidia.enable = mkEnableOption "NVIDIA GPU support";

  config = mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    };

    boot.kernelParams = [
      "nvidia_drm.fbdev=1"
      "nvidia_drm.modeset=1"
    ];

    boot.blacklistedKernelModules = [ "nouveau" ];
  };
}
