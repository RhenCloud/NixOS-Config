{ lib, config, ... }:
with lib;
let
  cfg = config.rhencloud.certs;
in
{
  options.rhencloud.certs.enable = mkEnableOption "SSL cert env vars";
  config = mkIf cfg.enable {
    home.sessionVariables = {
      SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-bundle.crt";
    };
  };
}
