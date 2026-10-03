{ lib, ... }:
{
  options.rhen.java.enable = lib.mkEnableOption "Java development tools";
}
