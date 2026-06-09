{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./c.nix
    ./android.nix
    # ./emacs.nix
    ./golang.nix
    ./java.nix
    # ./nixvim
    ./node.nix
    ./python.nix
    ./rust.nix
  ];
  home.packages = with pkgs; [
    inputs."siiway-cli".packages.${pkgs.stdenv.hostPlatform.system}.default
    act
    lychee
    lazygit
    cloudflared
    ghidra-bin
    codex
    opencode
    gitkraken
    cc-switch
    deno
  ];

  # programs.opencode = {
  #   settings = {
  #     lsp = true;
  #   };
  # };

  home.sessionVariables = {
    SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-bundle.crt";
  };
}
