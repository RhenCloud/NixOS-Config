{ lib, ... }:
{
  options.rhen.golang.enable = lib.mkEnableOption "Go development tools";
}
