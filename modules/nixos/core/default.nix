{ ... }:
{
  imports = [
    ./boot.nix
    ./identity.nix
    ./common.nix
    ./env.nix
    ./fonts.nix
    ./nvidia.nix
    ./fcitx5.nix
    # ./proxy.nix
  ];
}
