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
  readSecret = path: builtins.readFile "${inputs.self}/secrets/${path}";
  secret = builtins.replaceStrings [ "\n" ] [ "" ] (readSecret "sleepy-token");
  ghcrToken = builtins.replaceStrings [ "\n" ] [ "" ] (readSecret "opencode/github-token");
  ghcrPasswordFile = pkgs.writeText "sleepy-ghcr-password" ghcrToken;
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

    secret = mkOption {
      type = types.str;
      default = secret;
      description = "sleepy_main_secret（用于会话签名）";
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
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];

    virtualisation.oci-containers.containers.sleepy = {
      image = cfg.image;
      autoStart = true;
      pull = "always";

      volumes = [
        "${cfg.dataDir}:/sleepy/data"
      ];

      ports = [ "${toString cfg.port}:9010" ];

      environment = {
        sleepy_main_colorful_log = "false";
        sleepy_main_secret = cfg.secret;
        SLEEPY_PAGE_NAME = cfg.pageName;
      };

      login = {
        username = cfg.ghcrUser;
        passwordFile = "${ghcrPasswordFile}";
        registry = "ghcr.io";
      };
    };
  };
}
