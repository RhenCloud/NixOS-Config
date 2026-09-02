{ lib, ... }:
{
  options.rhencloud.hmOpenAgent.enable = lib.mkEnableOption "opencode agent config";
}
