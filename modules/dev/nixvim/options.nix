{ lib, ... }:
{
  options.rhencloud.nixvim.enable = lib.mkEnableOption "Neovim (nixvim)";
}
