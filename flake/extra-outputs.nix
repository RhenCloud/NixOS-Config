{ inputs }:
{
  nixosConfigurations.iso = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ../iso.nix
      inputs.impermanence.nixosModules.impermanence
    ];
  };
}
