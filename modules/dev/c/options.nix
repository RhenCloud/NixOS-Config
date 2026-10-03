{ lib, ... }:
{
  options.rhen.c.enable = lib.mkEnableOption "C/C++ development tools";
}
