{ lib, ... }:
{
  options.rhen.gdirect.enable = lib.mkEnableOption "gdirect Google Drive 直连客户端";
}
