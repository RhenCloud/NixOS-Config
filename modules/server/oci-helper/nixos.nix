{
  config,
  lib,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.oci-helper;
in
{
  options.rhencloud.services.oci-helper = {
    enable = mkEnableOption "oci-helper 甲骨文云管理面板";
    port = mkOption {
      type = types.port;
      default = 8818;
      description = "oci-helper 面板端口";
    };
    vncPort = mkOption {
      type = types.port;
      default = 6080;
      description = "websockify VNC 代理端口";
    };
    domain = mkOption {
      type = types.str;
      default = "oci.rhen.cloud";
      description = "面板访问域名";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/oci-helper";
      description = "数据目录";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."oci-helper-account" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.secrets."oci-helper-password" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.templates."oci-helper-application-yml" = {
      owner = "root";
      mode = "0444";
      content = ''
        server:
          port: ${toString cfg.port}

        web:
          account: ${config.sops.placeholder."oci-helper-account"}
          password: ${config.sops.placeholder."oci-helper-password"}

        spring:
          datasource:
            driver-class-name: org.sqlite.JDBC
            url: jdbc:sqlite:oci-helper.db
          sql:
            init:
              mode: always

        mybatis-plus:
          mapper-locations: classpath*:com/yohann/ocihelper/mapper/xml/*.xml

        logging:
          pattern:
            console: "%d{yyyy-MM-dd HH:mm:ss} %-5level %msg%n"
          level:
            com.oracle.bmc: error
            c.o.b.h.c.j: error

        oci-cfg:
          key-dir-path: /app/oci-helper/keys
      '';
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
      "d ${cfg.dataDir}/keys 0755 root root -"
      "f ${cfg.dataDir}/oci-helper.db 0644 root root -"
    ];

    systemd.services."podman-oci-helper" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    virtualisation.oci-containers.containers.oci-helper = {
      image = "ghcr.io/yohann0617/oci-helper:master";
      autoStart = true;
      pull = "newer";

      environment = {
        JAVA_TOOL_OPTIONS = "-Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=7890 -Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=7890 -Dhttp.nonProxyHosts=localhost|127.0.0.1";
      };

      volumes = [
        "${config.sops.templates."oci-helper-application-yml".path}:/app/oci-helper/application.yml:ro"
        "${cfg.dataDir}/oci-helper.db:/app/oci-helper/oci-helper.db"
        "${cfg.dataDir}/keys:/app/oci-helper/keys"
      ];

      extraOptions = [
        "--network=host"
      ];
    };

    systemd.services."podman-websockify" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    virtualisation.oci-containers.containers.websockify = {
      image = "ghcr.io/yohann0617/oci-helper-websockify:master";
      autoStart = true;
      pull = "newer";

      extraOptions = [
        "--network=host"
      ];
    };

    services.caddy = {
      virtualHosts.${cfg.domain} = {
        extraConfig = ''
          handle /myvnc/* {
            uri replace /myvnc/ /
            reverse_proxy 127.0.0.1:${toString cfg.vncPort}
          }

          reverse_proxy 127.0.0.1:${toString cfg.port}
        '';
      };
    };
  };
}
