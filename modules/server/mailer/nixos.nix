{
  config,
  lib,
  cloud,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.mailer;
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
    users.users.mailer = {
      uid = 10001;
      isSystemUser = true;
      group = "mailer";
    };
    users.groups.mailer = {
      gid = 10001;
    };

    sops.secrets."github-token" = cloud.sops.secret { source = "common"; } // {
      owner = "root";
      mode = "0400";
    };

    sops.secrets."mailer-config" =
      cloud.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "mailer";
        group = "mailer";
        mode = "0440";
      };

    sops.templates."mailer-config.yaml" = {
      owner = "mailer";
      group = "mailer";
      mode = "0440";
      content = config.sops.placeholder."mailer-config";
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 10001 10001 -"
    ];

    systemd.services."podman-mailer" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    virtualisation.oci-containers.containers.mailer = {
      image = cfg.image;
      autoStart = true;
      pull = "always";

      volumes = [
        "${config.sops.templates."mailer-config.yaml".path}:/app/config.yaml:ro"
        "${cfg.dataDir}:/app/data"
      ];

      environment = {
        TZ = "Asia/Shanghai";
      };

      login = {
        username = cfg.ghcrUser;
        passwordFile = config.sops.secrets."github-token".path;
        registry = "ghcr.io";
      };
    };
  };
}
