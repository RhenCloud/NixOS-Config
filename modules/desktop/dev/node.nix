{
  lib,
  pkgs,
  config,
  cloud,
  ...
}:
with lib;
let
  cfg = config.rhencloud.node;
in
{
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

    sops.secrets."npm-token" = cloud.sops.secret {
      source = "host";
      host = "nixos-desktop";
    };

    sops.templates."npmrc" = {
      mode = "0400";
      content = config.sops.placeholder."npm-token";
    };

    home.file.".npmrc".source = config.lib.file.mkOutOfStoreSymlink config.sops.templates."npmrc".path;
  };
}
