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
  ];
}
