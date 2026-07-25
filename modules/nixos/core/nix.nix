{ lib, config, ... }:
with lib;
let
  cfg = config.rhencloud.nix;
in {
  options.rhencloud.nix.enable = mkEnableOption "Nix daemon settings";
  config = mkIf cfg.enable {
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
