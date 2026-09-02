{ lib, ... }:
{
  options.rhencloud.emacs.enable = lib.mkEnableOption "Emacs editor";
}
