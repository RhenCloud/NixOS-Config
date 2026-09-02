{ lib, ... }:
{
  options.rhencloud.node.enable = lib.mkEnableOption "Node.js development tools";
}
