{ ... }:
{
  imports = [
    ./c.nix
    ./android.nix
    # ./emacs.nix
    ./golang.nix
    ./java.nix
    # nvf (Snowfall 自动发现，无需显式 imports)
    ./node.nix
    ./python.nix
    ./rust.nix
    ./packages.nix
    ./certs.nix
    ./siiway-opencode.nix
  ];
}
