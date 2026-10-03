{ lib, ... }:
{
  options.rhen.python.enable = lib.mkEnableOption "Python development tools";
}
