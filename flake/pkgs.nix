{ inputs, lib, ... }:
let
  h = import ./helpers.nix { inherit inputs lib; };
in
{
  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      localSystem = { inherit system; };
      config.allowUnfree = true;
      inherit (h) overlays;
    };
  };
}
