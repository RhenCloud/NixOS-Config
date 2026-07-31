{ config, lib, pkgs, inputs, ... }:
with lib;
let
  cfg = config.rhencloud.services.vaultwarden;
  readSecret = path: builtins.readFile "${inputs.self}/secrets/${path}";
in {
  options.rhencloud.services.vaultwarden = {
    enable = mkEnableOption "Vaultwarden 密码管理器";
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /var/lib/vaultwarden 0750 root root -"
    ];

    virtualisation.oci-containers.containers.vaultwarden = {
      image = "vaultwarden/server:latest";
      autoStart = true;

      volumes = [
        "/var/lib/vaultwarden:/data"
      ];

      ports = [ "1880:80" ];

      environment = {
        DOMAIN = "https://vw.rhen.cloud";
        SIGNUPS_ALLOWED = "true";
        ADMIN_TOKEN = readSecret "vaultwarden/admin-token";
      };

      extraOptions = [ "--pull=always" ];
    };
  };
}
