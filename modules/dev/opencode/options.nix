{ lib, ... }:
{
  options.rhen.hmOpenAgent.enable = lib.mkEnableOption "opencode agent config";
}
