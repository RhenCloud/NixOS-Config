{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.wyf9s-bot;
  readSecret = path: builtins.readFile "${inputs.self}/secrets/${path}";
  token = builtins.replaceStrings [ "\n" ] [ "" ] (readSecret "wyf9s-bot/token");
  tokenFile = pkgs.writeText "wyf9s-bot-tk.yaml" "token: ${token}";
  configFile = "${inputs.self}/modules/nixos/server/wyf9s-bot/config.yaml";
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
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];

    virtualisation.oci-containers.containers.wyf9s-bot = {
      image = cfg.image;
      autoStart = true;
      pull = "always";
      user = "0:0";

      volumes = [
        "${configFile}:/app/config/config.yaml:ro"
        "${tokenFile}:/app/config/tk.yaml:ro"
        "${cfg.dataDir}:/app/data"
      ];

      environment = {
        W9DCBOT_CONFIG = "/app/config/config.yaml";
        W9DCBOT_TOKEN_FILE = "/app/config/tk.yaml";
      };
    };
  };
}
