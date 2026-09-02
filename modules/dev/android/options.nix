{ lib, ... }:
{
  options.rhencloud.android.enable = lib.mkEnableOption "Android development tools";
}
