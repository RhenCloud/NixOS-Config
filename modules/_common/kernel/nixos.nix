{
  lib,
  pkgs,
  ...
}:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "boot.shell_on_fail"
    ];
    consoleLogLevel = 0;
  };
}
