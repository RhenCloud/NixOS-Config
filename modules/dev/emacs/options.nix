{ lib, ... }:
{
  options.rhen.emacs.enable = lib.mkEnableOption "Emacs editor";
}
