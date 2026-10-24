{
  config,
  lib,
  pkgs,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhen.services.gost;
in
{
  options.rhen.services.gost = {
    enable = mkEnableOption "gost 隧道转发";
  };

  config = mkIf cfg.enable {
    sops.secrets."gost-proxy-config" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.secrets."yc-hk-1-proxy-cert" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.secrets."yc-hk-1-proxy-key" =
      snowveil.sops.secret {
        source = "host";
        host = "yc-hk-1";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    environment.etc."gost/config.yaml".source = ./config.yaml;

    systemd.services.sing-box-gost = {
      description = "sing-box 上游代理适配器";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "sops-install-secrets.service"
      ];
      wants = [ "network-online.target" ];
      requires = [ "sops-install-secrets.service" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.sing-box}/bin/sing-box run -c ${config.sops.secrets."gost-proxy-config".path}";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    systemd.services.gost = {
      description = "gost 隧道转发服务";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.gost}/bin/gost -C /etc/gost/config.yaml";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    networking.firewall.allowedTCPPorts = [
      40079
      8891
    ];
    networking.firewall.allowedUDPPorts = [
      40037
      40053
      8882
      8883
      46091
    ]
    ++ (lib.range 40000 40019);
  };
}
