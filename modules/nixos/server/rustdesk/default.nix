{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.rustdesk;
in
{
  options.rhencloud.services.rustdesk = {
    enable = mkEnableOption "RustDesk 远程桌面服务端（hbbs + hbbr）";

    relayHost = mkOption {
      type = types.str;
      default = "83.229.127.169";
      description = "Relay 服务器公网 IP 或域名";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "是否开放 RustDesk 所需的防火墙端口";
    };
  };

  config = mkIf cfg.enable {
    services.rustdesk-server = {
      enable = true;
      openFirewall = cfg.openFirewall;
      signal.relayHosts = [ cfg.relayHost ];
    };
  };
}