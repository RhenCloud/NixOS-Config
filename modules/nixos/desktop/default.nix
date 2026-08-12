{ config, lib, ... }:
with lib;
let
  cfg = config.rhencloud.sunshine;
  avahiCfg = config.rhencloud.avahi;
in
{
  imports = [
    ./sops-secrets.nix
    ./hyprland.nix
    ./mangowm.nix
    ./thunar.nix
    ./games.nix
    ./steam.nix
    ./zen.nix
    ./packages.nix
  ];

  options = {
    rhencloud.sunshine.enable = mkEnableOption "Sunshine game streaming";
    rhencloud.avahi.enable = mkEnableOption "Avahi mDNS";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services.sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
      };
    })
    (mkIf avahiCfg.enable {
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        publish = {
          enable = true;
          userServices = true;
        };
      };
    })
  ];
}
