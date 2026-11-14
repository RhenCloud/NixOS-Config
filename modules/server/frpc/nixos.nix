{
  config,
  lib,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhen.services.frpc;
  credentialPath = "/run/credentials/frp-client.service/frp-auth-token";
in
{
  options.rhen.services.frpc = {
    enable = mkEnableOption "frp 客户端（把内网服务映射到 frps 所在的公网主机）";

    serverAddr = mkOption {
      type = types.str;
      default = "207.57.127.54";
      description = "frps 地址";
    };

    serverPort = mkOption {
      type = types.port;
      default = 7000;
      description = "frps 监听端口";
    };

    proxies = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "代理名称，需在同一个 frps 上唯一";
            };

            type = mkOption {
              type = types.enum [
                "tcp"
                "udp"
                "http"
                "https"
              ];
              default = "tcp";
              description = "代理类型";
            };

            localIP = mkOption {
              type = types.str;
              default = "127.0.0.1";
              description = "本地服务地址";
            };

            localPort = mkOption {
              type = types.port;
              description = "本地服务端口";
            };

            remotePort = mkOption {
              type = types.port;
              description = "frps 上的暴露端口（frps 的 proxyBindAddr 为 127.0.0.1）";
            };
          };
        }
      );
      default = [ ];
      description = "要暴露的内网服务列表";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."frp-auth-token" =
      snowveil.sops.secret {
        source = "host";
        host = config.networking.hostName;
      }
      // {
        mode = "0400";
      };

    services.frp.instances.client = {
      enable = true;
      role = "client";

      settings = {
        serverAddr = cfg.serverAddr;
        serverPort = cfg.serverPort;

        auth = {
          method = "token";
          tokenSource = {
            type = "file";
            file.path = credentialPath;
          };
        };

        proxies = cfg.proxies;
      };
    };

    # frpc 以 DynamicUser 运行，读不到 root:0400 的 secret，改用 systemd credential 传入
    systemd.services.frp-client = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
      serviceConfig.LoadCredential = [ "frp-auth-token:${config.sops.secrets."frp-auth-token".path}" ];
    };
  };
}
