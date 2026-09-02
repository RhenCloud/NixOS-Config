{
  config,
  lib,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.pds;
in
{
  options.rhencloud.services.pds = {
    enable = mkEnableOption "Bluesky PDS 个人数据服务器";

    role = mkOption {
      type = types.enum [
        "server"
        "proxy"
      ];
      default = "server";
      description = ''
        server：在本地运行 PDS Podman 容器，并通过 frp tcp 隧道把流量送到 yc-hk-1；
        proxy：在 yc-hk-1 侧用 Caddy 终止 TLS 并反代到 frp 隧道。
      '';
    };

    domain = mkOption {
      type = types.str;
      default = "bsky.rhen.cloud";
      description = "PDS 主机名与 handle 域名（账号形如 user.<domain>）";
    };

    frpServerAddr = mkOption {
      type = types.str;
      default = "83.229.127.169";
      description = "frp 服务端地址（yc-hk-1 公网 IP）";
    };

    frpServerPort = mkOption {
      type = types.port;
      default = 7000;
    };

    frpRemotePort = mkOption {
      type = types.port;
      default = 8443;
      description = "frp tcp 代理在 yc-hk-1 上监听的远程端口，作为 Caddy 反代目标";
    };

    pdsPort = mkOption {
      type = types.port;
      default = 3000;
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/bsky-pds";
    };

    image = mkOption {
      type = types.str;
      default = "ghcr.io/bluesky-social/pds:latest";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.role == "server") {
      sops.secrets = {
        "frp-auth-token" =
          snowveil.sops.secret {
            source = "host";
            host = "nixos-homeserver";
          }
          // {
            mode = "0644";
          };
        "pds-jwt-secret" =
          snowveil.sops.secret {
            source = "host";
            host = "nixos-homeserver";
          }
          // {
            mode = "0400";
          };
        "pds-admin-password" =
          snowveil.sops.secret {
            source = "host";
            host = "nixos-homeserver";
          }
          // {
            mode = "0400";
          };
        "pds-plc-rotation-key" =
          snowveil.sops.secret {
            source = "host";
            host = "nixos-homeserver";
          }
          // {
            mode = "0400";
          };
      };

      sops.templates."bsky-pds-env" = {
        owner = "root";
        mode = "0400";
        content = ''
          PDS_HOSTNAME=${cfg.domain}
          PDS_SERVICE_HANDLE_DOMAINS=.${cfg.domain}
          PDS_DATA_DIRECTORY=/pds
          PDS_BLOBSTORE_DISK_LOCATION=/pds/blocks
          PDS_BLOBSTORE_DISK_TMP_LOCATION=/pds/tmp
          PDS_DID_PLC_URL=https://plc.directory
          PDS_BSKY_APP_VIEW_URL=https://api.bsky.app
          PDS_BSKY_APP_VIEW_DID=did:web:api.bsky.app
          PDS_REPORT_SERVICE_URL=https://mod.bsky.app
          PDS_REPORT_SERVICE_DID=did:plc:ar7c4by46qjdydhdevvrndac
          PDS_CRAWLERS=https://bsky.network
          PDS_JWT_SECRET=${config.sops.placeholder."pds-jwt-secret"}
          PDS_ADMIN_PASSWORD=${config.sops.placeholder."pds-admin-password"}
          PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=${config.sops.placeholder."pds-plc-rotation-key"}
        '';
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0750 root root -"
      ];

      systemd.services."podman-bsky-pds" = {
        after = [ "sops-install-secrets.service" ];
        requires = [ "sops-install-secrets.service" ];
      };

      virtualisation.oci-containers.containers.bsky-pds = {
        image = cfg.image;
        autoStart = true;
        pull = "missing";
        volumes = [
          "${cfg.dataDir}:/pds"
        ];
        ports = [
          "127.0.0.1:${toString cfg.pdsPort}:3000"
        ];
        environmentFiles = [
          config.sops.templates."bsky-pds-env".path
        ];
      };

      services.frp.instances.bsky-pds = {
        enable = true;
        role = "client";
        settings = {
          serverAddr = cfg.frpServerAddr;
          serverPort = cfg.frpServerPort;
          auth = {
            method = "token";
            tokenSource = {
              type = "file";
              file.path = config.sops.secrets."frp-auth-token".path;
            };
          };
          proxies = [
            {
              name = "bsky-pds";
              type = "tcp";
              localIP = "127.0.0.1";
              localPort = cfg.pdsPort;
              remotePort = cfg.frpRemotePort;
            }
          ];
        };
      };

      systemd.services."frp-bsky-pds" = {
        after = [ "sops-install-secrets.service" ];
        requires = [ "sops-install-secrets.service" ];
      };
    })

    (mkIf (cfg.role == "proxy") {
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];

      services.caddy = {
        enable = true;
        globalConfig = ''
          on_demand_tls {
            ask http://127.0.0.1:${toString cfg.frpRemotePort}/tls-check
          }
        '';
        virtualHosts."*.${cfg.domain}" = {
          serverAliases = [ cfg.domain ];
          extraConfig = ''
            tls {
              on_demand
            }
            reverse_proxy 127.0.0.1:${toString cfg.frpRemotePort}

            @didJson path /.well-known/did.json
            handle @didJson {
              header Content-Type application/json
              respond `{"@context":["https://www.w3.org/ns/did/v1"],"id":"did:web:${cfg.domain}","service":[{"id":"#atproto_pds","type":"AtprotoPersonalDataServer","serviceEndpoint":"https://${cfg.domain}"}]}` 200
            }
          '';
        };
      };
    })
  ]);
}
