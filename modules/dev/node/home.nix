{
  lib,
  pkgs,
  config,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhencloud.node;
in
{
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

    sops.secrets."npm-token" = snowveil.sops.secret {
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
