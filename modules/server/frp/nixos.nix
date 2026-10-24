{
  config,
  lib,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhen.services.frp;
in
{
  options.rhen.services.frp = {
    enable = mkEnableOption "frp 服务端";
  };

  config = mkIf cfg.enable {
    sops.secrets."frp-auth-token" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        mode = "0400";
      };

    # frps 以 DynamicUser 运行，无法读取 root:0400 的 secret，改用 systemd credential 传入
    systemd.services."frp-server" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
      serviceConfig.LoadCredential = [
        "frp-auth-token:${config.sops.secrets."frp-auth-token".path}"
      ];
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
            file.path = "/run/credentials/frp-server.service/frp-auth-token";
          };
        };
      };
    };
  };
}
