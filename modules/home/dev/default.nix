{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./c.nix
    # ./emacs.nix
    ./golang.nix
    ./java.nix
    ./node.nix
    ./python.nix
    ./rust.nix
  ];
  home.packages = with pkgs; [
    inputs."siiway-cli".packages.${pkgs.stdenv.hostPlatform.system}.default
    act
    lychee
    lazygit
  ];
}
