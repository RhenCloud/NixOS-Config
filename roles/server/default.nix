{ config, lib, ... }:
with lib;
let
  cfg = config.rhencloud.roles.server;
in
{
  options.rhencloud.roles.server = {
    enable = mkEnableOption "服务器角色（容器、隧道与自托管服务）";
  };

  config = mkIf cfg.enable {
    rhencloud = {
      identity.enable = true;
      locale.enable = true;
      nix.enable = true;
      packages.enable = true;
      shells.enable = true;

      cloudflared.enable = true;
      services.postgresql.enable = true;
    };
  };
}
