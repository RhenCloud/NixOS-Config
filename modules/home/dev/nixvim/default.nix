{ lib, config, ... }:
with lib;
let
  cfg = config.rhencloud.nixvim;
in
{
  options.rhencloud.nixvim.enable = mkEnableOption "Neovim (nixvim)";
  config = mkIf cfg.enable {
    programs.nixvim.enable = true;
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