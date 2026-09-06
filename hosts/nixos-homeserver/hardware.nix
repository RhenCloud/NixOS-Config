{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ehci_pci"
    "ahci"
    "usbhid"
    "uas"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.supportedFilesystems = [ "ntfs" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/26b81091-6361-40bd-8e2a-54b3b6b49ec4";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/8787-653C";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/Data1" = {
    device = "/dev/disk/by-uuid/2348c396-f190-4f34-ae45-6739101205b3";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  fileSystems."/Data2" = {
    device = "/dev/disk/by-uuid/2D97AD940A9AD661";
    fsType = "ntfs";
    options = [ "nofail" ];
  };

  zramSwap = {
    enable = true;
    memoryPercent = 10;
  };

  networking.useDHCP = lib.mkDefault false;
  networking.useNetworkd = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
