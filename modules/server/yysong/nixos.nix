{
  config,
  lib,
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
        DATABASE_PROVIDER=sqlite
        DATABASE_URL=file:/data/app.db
        JWT_SECRET=${config.sops.placeholder."yysong-jwt-secret"}
        CREDENTIAL_KEY=${config.sops.placeholder."yysong-credential-key"}
        PORT=${toString cfg.port}
        HOST=0.0.0.0
        PUBLIC_BASE_URL=https://${cfg.domain}
      '';
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/yysong 0755 root root -"
      "d /var/lib/yysong/data 0755 root root -"
    ];

    systemd.services."podman-yysong" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    virtualisation.oci-containers.containers.yysong = {
      image = "ghcr.io/wemsur/yangyisongrequest:latest";
      autoStart = true;

      volumes = [
        "/var/lib/yysong/data:/data"
      ];

      ports = [ "${toString cfg.port}:3000" ];

      extraOptions = [ "--pull=always" ];

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
