{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.sleepy;
in
{
  options.rhencloud.services.sleepy = {
    enable = mkEnableOption "Sleepy 个人主页/状态页";

    image = mkOption {
      type = types.str;
      default = "ghcr.io/sleepy-project/sleepy:latest";
      description = "Sleepy OCI 镜像标签";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/sleepy";
      description = "数据目录（config.yaml、data.db、日志、证书）";
    };

    port = mkOption {
      type = types.port;
      default = 9010;
      description = "对外映射端口";
    };

    pageName = mkOption {
      type = types.str;
      default = "Sleepy";
      description = "SLEEPY_PAGE_NAME 页面标题";
    };

    ghcrUser = mkOption {
      type = types.str;
      default = "rhencloud";
      description = "GHCR 用户名（用于拉取镜像）";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."github-token" = {
      sopsFile = ../../../../secrets/common.yaml;
      owner = "root";
      mode = "0400";
    };

    sops.secrets."sleepy-token" = {
      sopsFile = ../../../../secrets/common.yaml;
      owner = "root";
      mode = "0400";
    };

    sops.templates."sleepy-env" = {
      owner = "root";
      mode = "0400";
      content = "sleepy_main_secret=${config.sops.placeholder."sleepy-token"}\n";
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];

    systemd.services."podman-sleepy" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    virtualisation.oci-containers.containers.sleepy = {
      image = cfg.image;
      autoStart = true;
      pull = "always";

      volumes = [
        "${cfg.dataDir}:/sleepy/data"
      ];

      ports = [ "${toString cfg.port}:9010" ];

      environmentFiles = [
        config.sops.templates."sleepy-env".path
      ];

      environment = {
        sleepy_main_colorful_log = "false";
        SLEEPY_PAGE_NAME = cfg.pageName;
      };

      login = {
        username = cfg.ghcrUser;
        passwordFile = config.sops.secrets."github-token".path;
        registry = "ghcr.io";
      };
    };
  };
}
