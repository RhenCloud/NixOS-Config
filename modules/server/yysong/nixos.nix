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
  pgPasswordSecret = "postgres-yysong-password";
  prismaConfig = pkgs.writeText "prisma.config.ts" ''
    import { defineConfig } from 'prisma/config';

    export default defineConfig({
      schema: 'prisma/schema.prisma',
      migrations: {
        path: 'prisma/migrations',
        seed: 'tsx prisma/seed.ts',
      },
      datasource: {
        url: process.env.DATABASE_URL ?? 'file:./data/app.db',
      },
    });
  '';

  startupScript = pkgs.writeShellScript "yysong-start.sh" ''
    cd /app
    exec npm run start:prod
  '';
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
      default = "music.100328.xyz";
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

    sops.templates."yysong-env" = {
      owner = "root";
      mode = "0400";
      content = ''
        JWT_SECRET=${config.sops.placeholder."yysong-jwt-secret"}
        CREDENTIAL_KEY=${config.sops.placeholder."yysong-credential-key"}
        DATABASE_PROVIDER=sqlite
        DATABASE_URL=file:/data/app.db
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
      image = "ghcr.io/wemsur/yangyisongrequest:latest";
      autoStart = true;
      user = "0:0";
      cmd = [
        "sh"
        "/app/yysong-start.sh"
      ];

      environment = {
        PORT = toString cfg.port;
        HOST = "0.0.0.0";
        PUBLIC_BASE_URL = "https://${cfg.domain}";
      };

      volumes = [
        "${prismaConfig}:/app/server/prisma.config.ts:ro"
        "${startupScript}:/app/yysong-start.sh:ro"
        "/var/lib/yysong/data:/data"
      ];

      extraOptions = [
        "--pull=always"
        "--network=host"
      ];

      environmentFiles = [
        config.sops.templates."yysong-env".path
      ];
    };

    services.caddy.virtualHosts.${cfg.domain} = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${toString cfg.port}
      '';
    };
  };
}
