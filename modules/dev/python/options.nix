{ lib, ... }:
{
  options.rhencloud.python.enable = lib.mkEnableOption "Python development tools";
}
