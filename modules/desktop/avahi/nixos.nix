{ config, lib, ... }:
{
  options.rhencloud.avahi.enable = lib.mkEnableOption "Avahi mDNS";
  config = lib.mkIf config.rhencloud.avahi.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };
  };
}
