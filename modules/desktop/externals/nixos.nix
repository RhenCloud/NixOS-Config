{ inputs, ... }:
{
  imports = [
    inputs.umbriel.nixosModules.default
    inputs.mangowm.nixosModules.mango
  ];
}
