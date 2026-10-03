{ lib, ... }:
{
  options.rhen.certs.enable = lib.mkEnableOption "SSL cert env vars";
}
