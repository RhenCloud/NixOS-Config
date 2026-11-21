{
  config,
  lib,
  pkgs,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhen.cloudflared;
  tunnelId = "5e94c131-1a39-4aed-865e-2c3e0e95c8b4";
  tokenSecret = "cloudflared-yc-hk-1-token";
in
{
  options.rhen.cloudflared.enable = mkEnableOption "Cloudflare Tunnel";

  config = mkIf cfg.enable {
    sops.secrets.${tokenSecret} =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    systemd.services."cloudflared-tunnel-${tunnelId}" = {
      description = "Cloudflare Tunnel ${tunnelId}";
      after = [
        "network-online.target"
        "sops-install-secrets.service"
      ];
      wants = [ "network-online.target" ];
      requires = [ "sops-install-secrets.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        LoadCredential = "token:${config.sops.secrets.${tokenSecret}.path}";
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel run --token-file %d/token";
        Restart = "on-failure";
        RestartSec = "5s";
        DynamicUser = true;
      };
    };
  };
}
