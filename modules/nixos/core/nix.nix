{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rhencloud.nix;
in {
  options.rhencloud.nix.enable = mkEnableOption "Nix daemon settings";
  config = mkIf cfg.enable {
    nixpkgs.overlays = [ (final: prev: {
      inherit (prev.lixPackageSets.stable)
        nixpkgs-review
        nix-eval-jobs
        nix-fast-build
        colmena;
    }) ];

    nix.package = pkgs.lixPackageSets.stable.lix;

    nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    accept-flake-config = true;
    max-jobs = "auto";
    builders-use-substitutes = true;
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };
  };
}
