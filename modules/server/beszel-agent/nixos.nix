{
  config,
  lib,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhen.services.beszel-agent;
in
{
  options.rhen.services.beszel-agent = {
    enable = mkEnableOption "Beszel Agent 监控客户端";

    image = mkOption {
      type = types.str;
      default = "docker.io/henrygd/beszel-agent:latest";
      description = "Beszel Agent OCI 镜像标签";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/beszel-agent";
      description = "数据目录";
    };

    listen = mkOption {
      type = types.port;
      default = 45876;
      description = "Agent 监听端口（host 网络模式）";
    };

    key = mkOption {
      type = types.str;
      default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOHL/S4dbKQVxJovkiUIsQ3YCNeCkOcU2he4g+hyRFTB";
      description = "Beszel Hub 公钥（用于建立连接）";
    };

    sopsHost = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = "sops host secrets 文件对应的主机名";
    };

    hubUrl = mkOption {
      type = types.str;
      default = "https://monitor.siiway.top";
      description = "HUB_URL，agent 连接的 Hub 地址";
    };

    dockerSocket = mkOption {
      type = types.nullOr types.str;
      default =
        if config.virtualisation.podman.dockerSocket.enable then
          "/run/podman/podman.sock"
        else if config.virtualisation.docker.enable then
          "/var/run/docker.sock"
        else
          null;
      description = "容器运行时 socket（只读挂载，用于采集容器指标）；设为 null 则禁用容器指标采集";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."beszel-agent-token" =
      snowveil.sops.secret {
        source = "host";
        host = cfg.sopsHost;
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.templates."beszel-agent-env" = {
      owner = "root";
      mode = "0400";
      content = "TOKEN=${config.sops.placeholder."beszel-agent-token"}\n";
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];

    systemd.services."${config.virtualisation.oci-containers.backend}-beszel-agent" = {
      after = [
        "sops-install-secrets.service"
      ]
      ++ optional (
        cfg.dockerSocket != null && config.virtualisation.podman.dockerSocket.enable
      ) "podman.socket"
      ++ optional (cfg.dockerSocket != null && config.virtualisation.docker.enable) "docker.service";
      requires = [
        "sops-install-secrets.service"
      ]
      ++ optional (
        cfg.dockerSocket != null && config.virtualisation.podman.dockerSocket.enable
      ) "podman.socket"
      ++ optional (cfg.dockerSocket != null && config.virtualisation.docker.enable) "docker.service";
    };

    systemd.sockets.podman.wantedBy = mkIf (
      cfg.dockerSocket != null && config.virtualisation.podman.dockerSocket.enable
    ) [ "multi-user.target" ];

    virtualisation.oci-containers.containers.beszel-agent = {
      image = cfg.image;
      autoStart = true;
      pull = "newer";

      extraOptions = [ "--network=host" ];

      volumes = [
        "${cfg.dataDir}:/var/lib/beszel-agent"
      ]
      ++ optional (cfg.dockerSocket != null) "${cfg.dockerSocket}:/var/run/docker.sock:ro";

      environmentFiles = [
        config.sops.templates."beszel-agent-env".path
      ];

      environment = {
        LISTEN = toString cfg.listen;
        KEY = cfg.key;
        HUB_URL = cfg.hubUrl;
      }
      // optionalAttrs (cfg.dockerSocket == null) {
        DOCKER_HOST = "";
      };
    };
  };
}
