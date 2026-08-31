{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.baota-probe;
in
{
  options.rhencloud.services.baota-probe = {
    enable = mkEnableOption "宝塔拨测探针（bt-probe-agent）";

    image = mkOption {
      type = types.str;
      default = "docker.cnb.cool/btpanel/bt-probe-agent:latest";
      description = "bt-probe-agent OCI 镜像标签";
    };

    etcDir = mkOption {
      type = types.str;
      default = "/etc/bt-probe-agent";
      description = "身份配置目录（config.json）";
    };

    libDir = mkOption {
      type = types.str;
      default = "/var/lib/bt-probe-agent";
      description = "历史数据目录（selfcheck.db / 日志 / activation.json）";
    };

    runDir = mkOption {
      type = types.str;
      default = "/run/bt-probe-agent";
      description = "运行时目录（socket / PID / 锁文件）";
    };

    controlPlaneUrl = mkOption {
      type = types.str;
      default = "https://t.bt.cn";
      description = "控制面地址（TBT_CONTROL_PLANE_URL）";
    };

    agentEndpoint = mkOption {
      type = types.str;
      default = "wss://t.bt.cn/ws/agent";
      description = "Agent WSS 接入点（TBT_AGENT_ENDPOINT）";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.etcDir} 0755 root root -"
      "d ${cfg.libDir} 0755 root root -"
      "d ${cfg.runDir} 0755 root root -"
    ];

    virtualisation.oci-containers.containers.bt-probe-agent = {
      image = cfg.image;
      autoStart = true;
      pull = "always";

      extraOptions = [
        "--cap-add=NET_RAW"
      ];

      volumes = [
        "${cfg.runDir}:/run/bt-probe-agent"
        "${cfg.etcDir}:/etc/bt-probe-agent"
        "${cfg.libDir}:/var/lib/bt-probe-agent"
      ];

      environment = {
        TBT_CONTROL_PLANE_URL = cfg.controlPlaneUrl;
        TBT_AGENT_ENDPOINT = cfg.agentEndpoint;
        BT_PROBE_LOG_MODE = "file";
      };
    };
  };
}
