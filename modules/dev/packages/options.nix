{ lib, ... }:
{
  options.rhen.hmDevPackages.enable = lib.mkEnableOption "development packages";
}
