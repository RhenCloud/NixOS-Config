{ lib, config, ... }:
with lib;
let
  cfg = config.rhencloud.nvf;
in {
  options.rhencloud.nvf.enable = mkEnableOption "Neovim (nvf)";
  config = mkIf cfg.enable {
    programs.nvf.enable = true;
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
