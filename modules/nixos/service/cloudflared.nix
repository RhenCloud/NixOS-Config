{ config, lib, pkgs, inputs, ... }:
with lib;
let
  readSecret = path: builtins.readFile "${inputs.self}/secrets/${path}";
  cfg = config.rhencloud.cloudflared;
  tunnelId = "eb4440a4-a4a8-4c22-8595-060df067653b";
  credentialsFile = pkgs.writeText "cloudflared-credentials.json" (readSecret "cloudflared/yc-hk-1-credentials.json");
in {
  options.rhencloud.cloudflared.enable = mkEnableOption "Cloudflare Tunnel";

  config = mkIf cfg.enable {
    services.cloudflared = {
      enable = true;
      tunnels."${tunnelId}" = {
        credentialsFile = "${credentialsFile}";
        default = "http_status:404";
        ingress = { };
      };
    };
  };
}
