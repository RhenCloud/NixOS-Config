{
  config,
  inputs,
  lib,
  pkgs,
  snowveil,
  ...
}:
let
  cfg = config.rhen.services.mihomo;
  package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.mihomo-meta;
  overrideFile = pkgs.writeText "mihomo-ebpf-override.yaml" (builtins.readFile ./override.yaml);
  extraListenersFile = pkgs.writeText "mihomo-extra-listeners.json" (
    builtins.toJSON {
      listeners = map (
        l:
        (lib.filterAttrs (_: v: v != null) {
          inherit (l) name type port;
          listen = l.listen;
          proxy = l.proxy;
        })
        // l.extraConfig
      ) cfg.extraListeners;
    }
  );
  mergeFiles = [
    config.sops.secrets."mihomo-config".path
  ]
  ++ lib.optional cfg.ebpf overrideFile
  ++ lib.optional (cfg.extraListeners != [ ]) extraListenersFile;
  hasOverride = cfg.ebpf || (cfg.extraListeners != [ ]);
  mergeScript = pkgs.writeShellScript "mihomo-merge" ''
    ${lib.getExe pkgs.yq-go} -P ea '. as $item ireduce ({}; . *+ $item)' \
      ${lib.escapeShellArgs mergeFiles} \
      > /run/mihomo/config.yaml
  '';
in
{
  options.rhen.services.mihomo = {
    enable = lib.mkEnableOption "mihomo proxy";
    ebpf = lib.mkEnableOption "mihomo eBPF local 入站与 CN-IP 内核绕过";
    extraListeners = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Listener 名称";
            };
            type = lib.mkOption {
              type = lib.types.enum [
                "mixed"
                "http"
                "socks"
                "tproxy"
                "redir"
              ];
              default = "mixed";
              description = "Listener 类型";
            };
            port = lib.mkOption {
              type = lib.types.port;
              description = "监听端口";
            };
            listen = lib.mkOption {
              type = lib.types.str;
              default = "127.0.0.1";
              description = "监听地址";
            };
            proxy = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "直接绑定的出站代理或策略组名称（为 null 则走规则路由）";
            };
            extraConfig = lib.mkOption {
              type = lib.types.attrsOf lib.types.anything;
              default = { };
              description = "其他自定义配置属性";
            };
          };
        }
      );
      default = [ ];
      description = "额外的 mihomo listener 列表";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."mihomo-config" = {
      sopsFile = snowveil.projectSource + "/secrets/mihomo.yaml";
      key = "";
      owner = "root";
      mode = "0400";
    };

    environment.etc."mihomo/config.yaml".source = config.sops.secrets."mihomo-config".path;

    systemd.services.mihomo = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
      serviceConfig = {
        ExecStart = lib.mkForce (
          if cfg.ebpf then
            "${lib.getExe package} -d /var/lib/mihomo -f /run/mihomo/config.yaml"
          else if hasOverride then
            "${pkgs.mihomo}/bin/mihomo -d /var/lib/mihomo -f /run/mihomo/config.yaml"
          else
            "${pkgs.mihomo}/bin/mihomo -d /var/lib/mihomo -f /etc/mihomo/config.yaml"
        );
      }
      // lib.optionalAttrs hasOverride {
        ExecStartPre = mergeScript;
        RuntimeDirectory = "mihomo";
        RuntimeDirectoryMode = "0700";
      }
      // lib.optionalAttrs cfg.ebpf {
        CapabilityBoundingSet = lib.mkForce [
          "CAP_NET_ADMIN"
          "CAP_BPF"
          "CAP_NET_RAW"
          "CAP_SYS_ADMIN"
        ];
        AmbientCapabilities = lib.mkForce [
          "CAP_NET_ADMIN"
          "CAP_BPF"
          "CAP_NET_RAW"
          "CAP_SYS_ADMIN"
        ];
        LimitMEMLOCK = "infinity";
      };
    };
  };
}
