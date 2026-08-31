{
  config,
  lib,
  cloud,
  ...
}:
let
  cfg = config.rhencloud.services;
  parts = lib.splitString "# __PROXIES_HERE__" (builtins.readFile ./config.yaml);
  headPart = builtins.head parts;
  tailPart = builtins.elemAt parts 1;
in
{
  config = lib.mkIf cfg.enable {
    sops.secrets."mihomo-proxies" =
      cloud.sops.secret {
        source = "host";
        host = "nixos-desktop";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.templates."mihomo-config.yaml" = {
      owner = "root";
      mode = "0400";
      content = headPart + config.sops.placeholder."mihomo-proxies" + tailPart;
    };

    systemd.services.mihomo = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    environment.etc."mihomo/config.yaml".source = config.sops.templates."mihomo-config.yaml".path;
  };
}
