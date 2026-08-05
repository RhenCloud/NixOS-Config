{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.vaultwarden;
in
{
  options.rhencloud.services.vaultwarden = {
    enable = mkEnableOption "Vaultwarden 密码管理器";
  };

  config = mkIf cfg.enable {
    sops.secrets."vaultwarden-admin-token" = {
      sopsFile = ../../../../secrets/hosts/yc-hk-1.yaml;
      owner = "root";
      mode = "0400";
    };

    sops.templates."vaultwarden-env" = {
      owner = "root";
      mode = "0400";
      content = "ADMIN_TOKEN=${config.sops.placeholder."vaultwarden-admin-token"}\n";
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/vaultwarden 0750 root root -"
    ];

    systemd.services."podman-vaultwarden" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    virtualisation.oci-containers.containers.vaultwarden = {
      image = "vaultwarden/server:latest";
      autoStart = true;

      volumes = [
        "/var/lib/vaultwarden:/data"
      ];

      ports = [ "1880:80" ];

      extraOptions = [ "--pull=always" ];

      environmentFiles = [
        config.sops.templates."vaultwarden-env".path
      ];

      environment = {
        DOMAIN = "https://vw.rhen.cloud";
        SIGNUPS_ALLOWED = "true";
      };
    };
  };
}
