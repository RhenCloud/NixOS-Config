{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.tokens;
  tokensPkg = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.tokens;
in
{
  config = mkIf cfg.enable {
    home.packages = [ tokensPkg ];

    systemd.user.services.tokens = {
      Unit = {
        Description = "tokens.ci 用量统计后台上报";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        ExecStart = "${tokensPkg}/bin/tokens serve";
        Restart = "always";
        RestartSec = 30;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
