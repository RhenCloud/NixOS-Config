{ lib, ... }:
{
  options.rhen.helix.enable = lib.mkEnableOption "Helix editor";
}
