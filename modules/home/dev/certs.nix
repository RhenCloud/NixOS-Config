{ ... }:
{
  home.sessionVariables = {
    SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-bundle.crt";
  };
}
