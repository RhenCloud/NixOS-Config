{ lib, ... }:
{
  options.rhencloud.golang.enable = lib.mkEnableOption "Go development tools";
}
