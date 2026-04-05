{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./c.nix
    ./golang.nix
    ./java.nix
    ./node.nix
    ./python.nix
    ./rust.nix
  ];
  home.packages = [
    inputs."siiway-cli".packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
