{ config, lib, ... }:
{
  options.rhen.avahi.enable = lib.mkEnableOption "Avahi mDNS";
  config = lib.mkIf config.rhen.avahi.enable {
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
