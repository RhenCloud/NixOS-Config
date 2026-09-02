{ lib, ... }:
{
  options.rhencloud.certs.enable = lib.mkEnableOption "SSL cert env vars";
}
