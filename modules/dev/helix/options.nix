{ lib, ... }:
{
  options.rhencloud.helix.enable = lib.mkEnableOption "Helix editor";
}
