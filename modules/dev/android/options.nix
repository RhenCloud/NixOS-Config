{ lib, ... }:
{
  options.rhen.android.enable = lib.mkEnableOption "Android development tools";
}
