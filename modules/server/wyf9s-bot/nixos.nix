{
  config,
  lib,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.wyf9s-bot;
  # 相对路径：只把单个文件进 store，避免 inputs.self 整仓复制导致
  # "store path was hashed … contents have changed" 评估失败
  configFile = ./config.yaml;
in
{
  options.rhencloud.services.wyf9s-bot = {
    enable = mkEnableOption "wyf9s Discord 多功能机器人";

    image = mkOption {
      type = types.str;
      default = "ghcr.io/wyf9/wyf9s-discord-bot:latest";
      description = "wyf9s-discord-bot OCI 镜像标签";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/wyf9s-bot";
      description = "运行时数据目录（perm.yaml / lang_settings.yaml / schedules.yaml / 日志）";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."wyf9s-bot-token" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.templates."wyf9s-bot-tk.yaml" = {
      owner = "root";
      mode = "0400";
      content = "token: ${config.sops.placeholder."wyf9s-bot-token"}";
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];

    systemd.services."podman-wyf9s-bot" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    virtualisation.oci-containers.containers.wyf9s-bot = {
      image = cfg.image;
      autoStart = true;
      pull = "always";
      user = "0:0";

      volumes = [
        "${configFile}:/app/config/config.yaml:ro"
        "${config.sops.templates."wyf9s-bot-tk.yaml".path}:/app/config/tk.yaml:ro"
        "${cfg.dataDir}:/app/data"
      ];

      environment = {
        W9DCBOT_CONFIG = "/app/config/config.yaml";
        W9DCBOT_TOKEN_FILE = "/app/config/tk.yaml";
      };
    };
  };
}
