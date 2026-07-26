{ lib, pkgs, config, inputs, ... }:
with lib;
let
  cfg = config.rhencloud.node;
  inherit (lib.strings) trim;
  npmToken = trim (builtins.readFile "${inputs.self}/secrets/home/npm-token");
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

    home.file.".npmrc".text = npmToken;
  };
}
