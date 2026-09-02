{
  config,
  lib,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhencloud.cloudflared;
  tunnelId = "eb4440a4-a4a8-4c22-8595-060df067653b";
in
{
  options.rhencloud.cloudflared.enable = mkEnableOption "Cloudflare Tunnel";

  config = mkIf cfg.enable {
    sops.secrets."cloudflared-yc-hk-1-credentials" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    systemd.services."cloudflared-tunnel-${tunnelId}" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    services.cloudflared = {
      enable = true;
      tunnels."${tunnelId}" = {
        credentialsFile = config.sops.secrets."cloudflared-yc-hk-1-credentials".path;
        default = "http_status:404";
        ingress = { };
      };
    };
  };
}
