{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhen.services.snowluma;
  ports = [
    cfg.novncPort
    cfg.webuiPort
    cfg.onebotHttpPort
    cfg.onebotWsPort
  ];
  containerService = "${config.virtualisation.oci-containers.backend}-snowluma";
  # bindAddress 为空表示发布到所有地址，否则只在该地址上监听。
  portSpec =
    port:
    if cfg.bindAddress == "" then
      "${toString port}:${toString port}"
    else
      "${cfg.bindAddress}:${toString port}:${toString port}";
in
{
  options.rhen.services.snowluma = {
    enable = mkEnableOption "SnowLuma QQ 网关";

    image = mkOption {
      type = types.str;
      default = "docker.io/motricseven7/snowluma:latest";
      description = "SnowLuma OCI 镜像标签";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/snowluma";
      description = "SnowLuma 持久化数据目录";
    };

    pull = mkOption {
      type = types.enum [
        "always"
        "missing"
        "never"
        "newer"
      ];
      default = "missing";
      description = ''
        镜像拉取策略。默认 missing：本地已存在时直接使用，避免慢速链路下
        每次启动都因联网检查更新而卡住。需要升级镜像时设为 newer 或 always。
      '';
    };

    novncPort = mkOption {
      type = types.port;
      default = 6081;
      description = "noVNC 主机端口，用于扫码登录";
    };

    webuiPort = mkOption {
      type = types.port;
      default = 5099;
      description = "SnowLuma WebUI 主机端口";
    };

    onebotHttpPort = mkOption {
      type = types.port;
      default = 3002;
      description = "OneBot HTTP 主机端口（避开 PDS 占用的 3000）";
    };

    onebotWsPort = mkOption {
      type = types.port;
      default = 3003;
      description = "OneBot WebSocket 主机端口（避开 PDS 占用的 3001）";
    };

    bindAddress = mkOption {
      type = types.str;
      default = "";
      example = "192.168.1.2";
      description = ''
        发布端口时绑定的主机地址。留空表示发布到所有地址（由主机防火墙限制来源）；
        填内网 IP 时端口只在该地址监听，可用于更严格的隔离。
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 root root -"
      # 卷挂载点必须先存在，否则 podman 会因 statfs 失败而拒绝启动。
      "d ${cfg.dataDir}/gateway 0750 root root -"
      "d ${cfg.dataDir}/config 0750 root root -"
      "d ${cfg.dataDir}/client 0750 root root -"
    ];

    virtualisation.oci-containers.containers.snowluma = {
      image = cfg.image;
      autoStart = true;
      pull = cfg.pull;
      extraOptions = [
        "--shm-size=1g"
        "--ulimit=nofile=65536:1048576"
        "--cap-add=SYS_PTRACE"
        "--security-opt=seccomp=unconfined"
      ];
      volumes = [
        "${cfg.dataDir}/gateway:/app/data"
        "${cfg.dataDir}/config:/app/.config"
        "${cfg.dataDir}/client:/app/.local/share"
      ];
      ports = map portSpec ports;
      environment = {
        # 容器内不需要主机代理：清空继承来的代理变量，避免把内网流量发往
        # 主机上并不存在的 127.0.0.1:7890。
        http_proxy = "";
        https_proxy = "";
        all_proxy = "";
        no_proxy = "localhost,127.0.0.1";
        SNOWLUMA_WEBUI_HOST = "0.0.0.0";
        SNOWLUMA_WEBUI_PORT = toString cfg.webuiPort;
        SNOWLUMA_QQ_FLAGS = "--disable-gpu --disable-software-rasterizer --disable-gpu-compositing";
      };
    };

    # 依赖容器端口发布，需在主机防火墙显式放行。
    networking.firewall.allowedTCPPorts = ports;

    systemd.services.${containerService} = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };
  };
}
