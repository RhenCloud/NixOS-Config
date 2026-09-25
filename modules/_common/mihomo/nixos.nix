{
  config,
  lib,
  snowveil,
  ...
}:
let
  cfg = config.rhencloud.services.mihomo;
  parts = lib.splitString "# __PROXIES_HERE__" (builtins.readFile ./config.yaml);
  headPart = builtins.head parts;
  tailPart = builtins.elemAt parts 1;
in
{
  options.rhencloud.services.mihomo = {
    enable = lib.mkEnableOption "mihomo proxy";
    host = lib.mkOption {
      type = lib.types.str;
      default = "nixos-desktop";
      description = "SOPS host to read mihomo-proxies secret from";
    };
    enableTun = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether Mihomo should take over system traffic through TUN";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."mihomo-proxies" =
      snowveil.sops.secret {
        source = "host";
        host = cfg.host;
      }
      // {
        owner = "root";
        mode = "0400";
      };

    sops.templates."mihomo-config.yaml" = {
      owner = "root";
      mode = "0400";
      content = lib.replaceStrings [ "__TUN_ENABLED__" ] [ (if cfg.enableTun then "true" else "false") ] (
        headPart + config.sops.placeholder."mihomo-proxies" + tailPart
      );
    };

    systemd.services.mihomo = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
    };

    environment.etc."mihomo/config.yaml".source = config.sops.templates."mihomo-config.yaml".path;
  };
}
