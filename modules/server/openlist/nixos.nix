{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhen.services.openlist;
  containerService = "${config.virtualisation.oci-containers.backend}-openlist";
in
{
  options.rhen.services.openlist = {
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
      description = "对外映射端口（hostNetwork 下即容器自身监听端口）";
    };

    volumes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/Data2:/Data2" ];
      description = ''
        额外的宿主路径挂载，格式为 "宿主路径:容器路径"。
        离线下载要求下载器与 OpenList 看到完全一致的绝对路径，
        因此建议宿主路径与容器路径保持一致（例如 /Data2:/Data2）。
      '';
    };

    hostNetwork = mkOption {
      type = types.bool;
      default = false;
      description = ''
        使用宿主网络命名空间。开启后容器内 localhost 即宿主，
        便于直接连接宿主上的 aria2 RPC（127.0.0.1:6800），同时不再映射端口。
      '';
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "额外的容器运行参数";
    };

    pullPolicy = mkOption {
      type = types.enum [
        "always"
        "missing"
        "never"
        "newer"
      ];
      default = "newer";
      description = ''
        镜像拉取策略。镜像源不稳定时设为 "missing"，
        避免每次启动都联网校验而挂起。
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];

    virtualisation.oci-containers.containers.openlist = {
      image = cfg.image;
      autoStart = true;
      pull = cfg.pullPolicy;
      user = "0:0";
      extraOptions = [
        "--userns=host"
      ]
      ++ optionals cfg.hostNetwork [ "--network=host" ]
      ++ cfg.extraOptions;

      volumes = [ "${cfg.dataDir}:/opt/openlist/data" ] ++ cfg.volumes;

      # hostNetwork 下端口映射无意义，podman 会直接忽略 -p
      ports = optionals (!cfg.hostNetwork) [ "${toString cfg.port}:5244" ];

      environment = {
        UMASK = "022";
      };
    };

    # 数据目录或额外挂载（如 /Data2）在 nofail 磁盘上时必须等挂载完成再启动容器，
    # 否则 OpenList 会在未挂载的空目录上初始化 data.db。
    systemd.services.${containerService}.unitConfig.RequiresMountsFor = [
      cfg.dataDir
    ]
    ++ map (volume: head (splitString ":" volume)) cfg.volumes;
  };
}
