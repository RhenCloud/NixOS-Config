{ config, lib, ... }:
{
  options.rhen.sunshine.enable = lib.mkEnableOption "Sunshine game streaming";
  config = lib.mkIf config.rhen.sunshine.enable {
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
    };
  };
}
