{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.gost;
in
{
  options.rhencloud.services.gost = {
    enable = mkEnableOption "gost 隧道转发";
  };

  config = mkIf cfg.enable {
    environment.etc."gost/config.yaml".source = ./config.yaml;

    systemd.services.gost = {
      description = "gost 隧道转发服务";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.gost}/bin/gost -C /etc/gost/config.yaml";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
