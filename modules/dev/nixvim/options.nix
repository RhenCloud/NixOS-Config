{ lib, ... }:
{
  options.rhen.nixvim.enable = lib.mkEnableOption "Neovim (nixvim)";
}
