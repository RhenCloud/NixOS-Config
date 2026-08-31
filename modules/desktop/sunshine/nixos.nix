{ config, lib, ... }:
{
  options.rhencloud.sunshine.enable = lib.mkEnableOption "Sunshine game streaming";
  config = lib.mkIf config.rhencloud.sunshine.enable {
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
    };
  };
}
