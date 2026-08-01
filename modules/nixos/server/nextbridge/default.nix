{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.nextbridge;
  readSecret = path: builtins.readFile "${inputs.self}/secrets/${path}";
  ghcrToken = builtins.replaceStrings [ "\n" ] [ "" ] (readSecret "opencode/github-token");
  ghcrPasswordFile = pkgs.writeText "nextbridge-ghcr-password" ghcrToken;
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
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
      "d ${cfg.dataDir}/logs 0755 root root -"
    ];

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
        passwordFile = "${ghcrPasswordFile}";
        registry = "ghcr.io";
      };
    };
  };
}
