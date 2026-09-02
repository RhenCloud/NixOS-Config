{ lib, ... }:
{
  options.rhencloud.java.enable = lib.mkEnableOption "Java development tools";
}
