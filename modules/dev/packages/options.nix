{ lib, ... }:
{
  options.rhencloud.hmDevPackages.enable = lib.mkEnableOption "development packages";
}
