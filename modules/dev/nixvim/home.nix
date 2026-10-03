{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhen.nixvim;
in
{
  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      nixpkgs.source = pkgs.path;
    };
  };

  imports = [
    ./core.nix
    ./keymaps.nix
    ./languages.nix
    ./plugins.nix
    ./rime.nix
    ./neovide.nix
  ];
}
