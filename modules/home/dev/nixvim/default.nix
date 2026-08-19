{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.nixvim;
in
{
  options.rhencloud.nixvim.enable = mkEnableOption "Neovim (nixvim)";
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
