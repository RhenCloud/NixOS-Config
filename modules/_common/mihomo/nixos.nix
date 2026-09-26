{
  config,
  lib,
  ...
}:
let
  cfg = config.rhencloud.services.mihomo;
in
{
  options.rhencloud.services.mihomo = {
    enable = lib.mkEnableOption "mihomo proxy";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."mihomo-config" = {
      sopsFile = ../../../secrets/mihomo.yaml;
      key = "";
      owner = "root";
      mode = "0400";
    };

    systemd.services.mihomo = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    environment.etc."mihomo/config.yaml".source = config.sops.secrets."mihomo-config".path;
  };
}
