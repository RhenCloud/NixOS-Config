{ lib, ... }:
{
  options.rhencloud.c.enable = lib.mkEnableOption "C/C++ development tools";
}
