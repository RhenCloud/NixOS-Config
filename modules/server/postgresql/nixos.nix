{
  config,
  lib,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.postgresql;
  secretOptions =
    snowveil.sops.secret {
      source = "host";
      host = "yc-hk-1";
    }
    // {
      owner = "postgres";
      group = "postgres";
      mode = "0440";
    };
  initScript = ''
    #!/usr/bin/env bash
    set -e
  ''
  + (lib.concatMapStringsSep "\n" (db: ''
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
      DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${db.user}') THEN CREATE ROLE ${db.user} LOGIN PASSWORD '${
        config.sops.placeholder."${db.passwordSecret}"
      }'; END IF; END $$;
      SELECT 'CREATE DATABASE ${db.name} OWNER ${db.user}'
      WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${db.name}')\gexec
    EOSQL
  '') cfg.databases)
  + "\n";
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
      type = types.listOf (
        types.submodule {
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
              description = "sops secrets 键名（hosts/yc-hk-1.yaml 顶层 key）";
            };
          };
        }
      );
      default = [ ];
      description = "额外创建的数据库和用户（首次初始化时执行）";
    };
  };

  config = mkIf cfg.enable {
    users.users.postgres = {
      isSystemUser = true;
      group = "postgres";
    };
    users.groups.postgres = {
      gid = 999;
    };

    sops.secrets = lib.listToAttrs (
      [
        {
          name = "postgres-postgres-password";
          value = secretOptions;
        }
      ]
      ++ map (db: {
        name = db.passwordSecret;
        value = secretOptions;
      }) cfg.databases
    );

    sops.templates."postgresql-init.sh" = {
      owner = "postgres";
      group = "postgres";
      mode = "0440";
      content = initScript;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0770 postgres postgres -"
    ];

    systemd.services."podman-postgresql" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    virtualisation.oci-containers.containers.postgresql = {
      image = cfg.image;
      autoStart = true;
      pull = "always";

      volumes = [
        "${cfg.dataDir}:/var/lib/postgresql/data"
        "${config.sops.templates."postgresql-init.sh".path}:/docker-entrypoint-initdb.d/10-init.sh:ro"
        "${config.sops.secrets."postgres-postgres-password".path}:/run/secrets/postgres-password:ro"
      ];

      ports = [ "127.0.0.1:${toString cfg.port}:5432" ];

      environment = {
        POSTGRES_USER = cfg.superuser;
        POSTGRES_DB = cfg.initialDatabase;
        POSTGRES_PASSWORD_FILE = "/run/secrets/postgres-password";
        PGDATA = "/var/lib/postgresql/data";
      };
    };
  };
}
