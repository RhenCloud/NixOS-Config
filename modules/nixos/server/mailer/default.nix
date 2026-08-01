{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.mailer;
  readSecret = path: builtins.readFile "${inputs.self}/secrets/${path}";
  ghcrToken = builtins.replaceStrings [ "\n" ] [ "" ] (readSecret "opencode/github-token");
  ghcrPasswordFile = pkgs.writeText "mailer-ghcr-password" ghcrToken;
  configFile = pkgs.writeText "mailer-config.yaml" (readSecret "mailer/config.yaml");
in
{
  options.rhencloud.services.mailer = {
    enable = mkEnableOption "Mailer 邮件监控通知服务";

    image = mkOption {
      type = types.str;
      default = "ghcr.io/recloudstudio/mailer:latest";
      description = "Mailer OCI 镜像标签";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/mailer";
      description = "state.db 持久化路径";
    };

    ghcrUser = mkOption {
      type = types.str;
      default = "rhencloud";
      description = "GHCR 用户名（用于拉取镜像）";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 10001 10001 -"
    ];

    virtualisation.oci-containers.containers.mailer = {
      image = cfg.image;
      autoStart = true;
      pull = "always";

      volumes = [
        "${configFile}:/app/config.yaml:ro"
        "${cfg.dataDir}:/app/data"
      ];

      environment = {
        TZ = "Asia/Shanghai";
      };

      login = {
        username = cfg.ghcrUser;
        passwordFile = "${ghcrPasswordFile}";
        registry = "ghcr.io";
      };
    };
  };
}
