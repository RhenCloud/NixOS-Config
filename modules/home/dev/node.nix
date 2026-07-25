{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rhencloud.node;
in {
  options.rhencloud.node.enable = mkEnableOption "Node.js development tools";
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
    nodejs_latest
    nodenv
    pnpm
    wrangler
  ];
    programs.bun = {
      enable = true;
    };
  };
}
