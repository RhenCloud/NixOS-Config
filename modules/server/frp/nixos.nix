{
  config,
  lib,
  cloud,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.frp;
in
{
  options.rhencloud.services.frp = {
    enable = mkEnableOption "frp 服务端";
  };

  config = mkIf cfg.enable {
    sops.secrets."frp-auth-token" =
      cloud.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        mode = "0644";
      };

    systemd.services."frp-server" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    services.frp.instances.server = {
      enable = true;
      role = "server";

      settings = {
        bindPort = 7000;
        proxyBindAddr = "127.0.0.1";
        webServer.addr = "0.0.0.0";
        webServer.port = 8080;
        subdomainHost = "rhen.cloud";
        auth = {
          method = "token";
          tokenSource = {
            type = "file";
            file.path = config.sops.secrets."frp-auth-token".path;
          };
        };
      };
    };
  };
}
