{ ... }:
{
  imports = [
    ./boot.nix
    ./identity.nix
    ./env.nix
    ./fonts.nix
    ./nvidia.nix
    ./fcitx5.nix
    ./locale.nix
    ./nix.nix
    ./packages.nix
    ./services.nix
    ./shells.nix
    ./users.nix
    ./xdg.nix
    # ./proxy.nix
  ];
}
