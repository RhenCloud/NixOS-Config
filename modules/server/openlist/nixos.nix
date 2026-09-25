{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.openlist;
in
{
  options.rhencloud.services.openlist = {
    enable = mkEnableOption "OpenList 文件列表程序";

    image = mkOption {
      type = types.str;
      default = "docker.io/openlistteam/openlist:latest";
      description = "OpenList OCI 镜像标签";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/openlist";
      description = "数据目录（config.json、data.db）";
    };

    port = mkOption {
      type = types.port;
      default = 5244;
      description = "对外映射端口";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];

    virtualisation.oci-containers.containers.openlist = {
      image = cfg.image;
      autoStart = true;
      pull = "newer";
      user = "0:0";
      extraOptions = [ "--userns=host" ];

      volumes = [
        "${cfg.dataDir}:/opt/openlist/data"
      ];

      ports = [ "${toString cfg.port}:5244" ];

      environment = {
        UMASK = "022";
      };
    };
  };
}
