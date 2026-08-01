{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.frp;
  readSecret = path: builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile "${inputs.self}/secrets/${path}");
in
{
  options.rhencloud.services.frp = {
    enable = mkEnableOption "frp 服务端";
  };

  config = mkIf cfg.enable {
    services.frp.instances.server = {
      enable = true;
      role = "server";

      settings = {
        bindPort = 7000;
        webServer.addr = "0.0.0.0";
        webServer.port = 8080;
        subdomainHost = "rhen.cloud";
        auth.method = "token";
        auth.token = readSecret "frp/auth-token";
      };
    };
  };
}
