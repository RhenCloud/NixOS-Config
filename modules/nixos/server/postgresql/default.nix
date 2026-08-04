{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.postgresql;
  readSecret = path: builtins.readFile "${inputs.self}/secrets/${path}";
  postgresPassword = builtins.replaceStrings [ "\n" ] [ "" ] (readSecret "postgresql/postgres-password");
  initScript = pkgs.writeText "postgresql-init.sh" (''
    #!/usr/bin/env bash
    set -e
  '' + (lib.concatMapStringsSep "\n" (db: let
    password = builtins.replaceStrings [ "\n" ] [ "" ] (readSecret db.passwordSecret);
  in ''
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
      DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${db.user}') THEN CREATE ROLE ${db.user} LOGIN PASSWORD '${password}'; END IF; END $$;
      SELECT 'CREATE DATABASE ${db.name} OWNER ${db.user}'
      WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${db.name}')\gexec
    EOSQL
  '') cfg.databases) + "\n");
in
{
  options.rhencloud.services.postgresql = {
    enable = mkEnableOption "PostgreSQL 数据库";

    image = mkOption {
      type = types.str;
      default = "docker.io/library/postgres:17";
      description = "PostgreSQL OCI 镜像标签";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/postgresql";
      description = "数据目录（PGDATA 挂载点）";
    };

    port = mkOption {
      type = types.port;
      default = 5432;
      description = "本机监听端口";
    };

    superuser = mkOption {
      type = types.str;
      default = "postgres";
      description = "超级用户";
    };

    initialDatabase = mkOption {
      type = types.str;
      default = "postgres";
      description = "初始数据库名";
    };

    databases = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "数据库名";
          };
          user = mkOption {
            type = types.str;
            description = "数据库用户";
          };
          passwordSecret = mkOption {
            type = types.str;
            description = "密码密钥路径（相对 secrets/ 目录）";
          };
        };
      });
      default = [ ];
      description = "额外创建的数据库和用户（首次初始化时执行）";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0700 999 999 -"
    ];

    virtualisation.oci-containers.containers.postgresql = {
      image = cfg.image;
      autoStart = true;
      pull = "always";

      volumes = [
        "${cfg.dataDir}:/var/lib/postgresql/data"
        "${initScript}:/docker-entrypoint-initdb.d/10-init.sh:ro"
      ];

      ports = [ "127.0.0.1:${toString cfg.port}:5432" ];

      environment = {
        POSTGRES_USER = cfg.superuser;
        POSTGRES_PASSWORD = postgresPassword;
        POSTGRES_DB = cfg.initialDatabase;
        PGDATA = "/var/lib/postgresql/data";
      };
    };
  };
}
