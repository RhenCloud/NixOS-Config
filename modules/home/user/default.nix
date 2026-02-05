{ inputs
, config
, pkgs
, ...
}:

{
  imports = [
    ./fastfetch.nix
    # ./fcitx5.nix
    ./noctalia.nix
    ./rofi.nix
    ./wechat.nix
    ./theme.nix
    # ./dev
  ];

  # _module.args = {
  #   inherit inputs;
  # };
}
