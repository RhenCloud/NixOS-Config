{
  config,
  lib,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.nextbridge;
in
{
  options.rhencloud.services.nextbridge = {
    enable = mkEnableOption "NextBridge 多平台聊天桥接";

    image = mkOption {
      type = types.str;
      default = "ghcr.io/siiway/nextbridge:unstable";
      description = "NextBridge OCI 镜像标签";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/nextbridge";
      description = "配置文件和数据库的持久化路径";
    };

    logLevel = mkOption {
      type = types.enum [
        "DEBUG"
        "INFO"
        "WARNING"
        "ERROR"
      ];
      default = "INFO";
      description = "日志级别";
    };

    ghcrUser = mkOption {
      type = types.str;
      default = "rhencloud";
      description = "GHCR 用户名（用于拉取镜像）";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."github-token" = snowveil.sops.secret { source = "common"; } // {
      owner = "root";
      mode = "0400";
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
      "d ${cfg.dataDir}/logs 0755 root root -"
    ];

    systemd.services."podman-nextbridge" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    virtualisation.oci-containers.containers.nextbridge = {
      image = cfg.image;
      autoStart = true;
      pull = "always";

      volumes = [
        "${cfg.dataDir}:/app/data"
        "${cfg.dataDir}/logs:/app/logs"
      ];

      environment = {
        NEXTBRIDGE_DATA_DIR = "/app/data";
        LOG_LEVEL = cfg.logLevel;
      };

      extraOptions = [ "--network=host" ];

      login = {
        username = cfg.ghcrUser;
        passwordFile = config.sops.secrets."github-token".path;
        registry = "ghcr.io";
      };
    };
  };
}
