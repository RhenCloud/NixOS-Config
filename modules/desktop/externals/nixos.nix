{ inputs, ... }:
{
  imports = [
    inputs.umbriel.nixosModules.default
    inputs.mangowm.nixosModules.mango
    inputs.linuxqq-wayland-fix.nixosModules.default
  ];
}
