{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.beszel;
in
{
  options.rhencloud.services.beszel = {
    enable = mkEnableOption "Beszel Hub 服务器监控中心";

    image = mkOption {
      type = types.str;
      default = "docker.io/henrygd/beszel:latest";
      description = "Beszel Hub OCI 镜像标签";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/beszel";
      description = "数据目录（beszel.db）";
    };

    port = mkOption {
      type = types.port;
      default = 8090;
      description = "本机监听端口（供 Cloudflare Tunnel 反向代理）";
    };

    appUrl = mkOption {
      type = types.str;
      default = "https://dash.rhen.cloud";
      description = "APP_URL，agent 连接 Hub 的公开地址";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];

    virtualisation.oci-containers.containers.beszel = {
      image = cfg.image;
      autoStart = true;
      pull = "always";

      volumes = [
        "${cfg.dataDir}:/beszel_data"
      ];

      ports = [ "127.0.0.1:${toString cfg.port}:8090" ];

      environment = {
        APP_URL = cfg.appUrl;
      };
    };
  };
}
