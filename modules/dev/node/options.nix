{ lib, ... }:
{
  options.rhen.node.enable = lib.mkEnableOption "Node.js development tools";
}
