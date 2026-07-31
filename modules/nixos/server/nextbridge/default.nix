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
  ghcrToken = readSecret "opencode/github-token";
in
{
  options.rhencloud.services.nextbridge = {
    enable = mkEnableOption "NextBridge 多平台聊天桥接";

    image = mkOption {
      type = types.str;
      default = "ghcr.io/siiway/nextbridge:unstable";
      description = "NextBridge Docker 镜像标签";
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

    systemd.services.docker-nextbridge-pull = {
      description = "Pre-pull NextBridge Docker image";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        echo ${escapeShellArg ghcrToken} | docker login ghcr.io -u ${escapeShellArg cfg.ghcrUser} --password-stdin
        docker pull ${cfg.image}
      '';
      wantedBy = [ "nextbridge.service" ];
      before = [ "nextbridge.service" ];
    };

    systemd.services.nextbridge = {
      description = "NextBridge 多平台聊天桥接";
      after = [ "docker.service" "network.target" ];
      wants = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "10";
        ExecStartPre = "-${pkgs.docker}/bin/docker rm -f nextbridge";
        ExecStart = ''
          ${pkgs.docker}/bin/docker run \
            --rm \
            --name nextbridge \
            --network host \
            -v ${cfg.dataDir}:/app/data \
            -v ${cfg.dataDir}/logs:/app/logs \
            -e NEXTBRIDGE_DATA_DIR=/app/data \
            -e LOG_LEVEL=${cfg.logLevel} \
            ${cfg.image}
        '';
        ExecStop = "${pkgs.docker}/bin/docker stop nextbridge";
      };
    };
  };
}
