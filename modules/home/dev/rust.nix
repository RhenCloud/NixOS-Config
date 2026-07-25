{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rhencloud.rust;
in {
  options.rhencloud.rust.enable = mkEnableOption "Rust development tools";
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
    rustup
  ];
  };
}
