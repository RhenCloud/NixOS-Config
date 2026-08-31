{
  config,
  lib,
  cloud,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.beszel-agent;
in
{
  options.rhencloud.services.beszel-agent = {
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
      default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxZ7wvnk1ycVMLveoDM+O0uC1nfukOe57EmhIB4EHSX";
      description = "Beszel Hub 公钥（用于建立连接）";
    };

    hubUrl = mkOption {
      type = types.str;
      default = "https://dash.rhen.cloud";
      description = "HUB_URL，agent 连接的 Hub 地址";
    };

    dockerSocket = mkOption {
      type = types.str;
      default = "/var/run/docker.sock";
      description = "容器运行时 socket（只读挂载，用于采集容器指标）";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."beszel-agent-token" =
      cloud.sops.secret {
        source = "host";
        host = "nixos-homeserver";
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

    systemd.services."podman-beszel-agent" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    virtualisation.oci-containers.containers.beszel-agent = {
      image = cfg.image;
      autoStart = true;
      pull = "always";

      extraOptions = [ "--network=host" ];

      volumes = [
        "${cfg.dockerSocket}:/var/run/docker.sock:ro"
        "${cfg.dataDir}:/var/lib/beszel-agent"
      ];

      environmentFiles = [
        config.sops.templates."beszel-agent-env".path
      ];

      environment = {
        LISTEN = toString cfg.listen;
        KEY = cfg.key;
        HUB_URL = cfg.hubUrl;
      };
    };
  };
}
