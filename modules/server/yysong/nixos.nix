{
  config,
  lib,
  pkgs,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.yysong;
in
{
  options.rhencloud.services.yysong = {
    enable = mkEnableOption "杨一之声在线点歌系统";
    port = mkOption {
      type = types.port;
      default = 3000;
      description = "服务监听端口";
    };
    domain = mkOption {
      type = types.str;
      default = "ycyztv.cn";
      description = "站点域名";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."yysong-jwt-secret" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.secrets."yysong-credential-key" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.secrets."yysong-admin-username" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.secrets."yysong-admin-password" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.secrets."yysong-s3-access-key" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.secrets."yysong-s3-secret-key" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.secrets."yysong-smtp-pass" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.templates."yysong-env" = {
      owner = "root";
      mode = "0400";
      content = ''
        JWT_SECRET=${config.sops.placeholder."yysong-jwt-secret"}
        CREDENTIAL_KEY=${config.sops.placeholder."yysong-credential-key"}
        DATABASE_PROVIDER=sqlite
        DATABASE_URL=/data/app.db
        INITIAL_ADMIN_USERNAME=${config.sops.placeholder."yysong-admin-username"}
        INITIAL_ADMIN_PASSWORD=${config.sops.placeholder."yysong-admin-password"}
        S3_ENDPOINT=https://731b927733dccabbd9210b33c3ee513e.r2.cloudflarestorage.com
        S3_REGION=auto
        S3_BUCKET=yysong
        S3_ACCESS_KEY_ID=${config.sops.placeholder."yysong-s3-access-key"}
        S3_SECRET_ACCESS_KEY=${config.sops.placeholder."yysong-s3-secret-key"}
        SMTP_HOST=mail.rhen.cloud
        SMTP_PORT=465
        SMTP_USER=noreply@rhen.cloud
        SMTP_PASS=${config.sops.placeholder."yysong-smtp-pass"}
        SMTP_FROM=杨村一中校园广电 <noreply@rhen.cloud>
        TRUSTED_PROXY_IPS=127.0.0.1,47.243.223.74
        INTERNAL_RATE_LIMIT_ENABLED=true
      '';
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/yysong/data 0755 root root - -"
    ];

    systemd.services."podman-yysong" = {
      after = [
        "sops-install-secrets.service"
      ];
      requires = [ "sops-install-secrets.service" ];
    };

    virtualisation.oci-containers.containers.yysong = {
      image = "ghcr.io/onionschool/yangyisongrequest:latest";
      autoStart = true;

      environment = {
        PORT = toString cfg.port;
        HOST = "0.0.0.0";
        PUBLIC_BASE_URL = "https://${cfg.domain}";
        NODE_ENV = "production";
      };

      volumes = [
        "/var/lib/yysong/data:/data"
      ];

      user = "0:0";

      pull = "newer";

      extraOptions = [
        "--network=host"
      ];

      environmentFiles = [
        config.sops.templates."yysong-env".path
      ];
    };

    services.caddy = {
      globalConfig = ''
        servers {
          trusted_proxies static {
            ranges 47.243.223.74
          }
        }
      '';
      virtualHosts.${cfg.domain} = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:${toString cfg.port}
        '';
      };
    };
  };
}
