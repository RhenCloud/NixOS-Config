{
  nixos = [
    "_common.identity"
    "_common.locale"
    "_common.nix"
    "_common.packages"
    "_common.shells"

    "_common.cloudflared"
    "server.postgresql"
  ];
}
