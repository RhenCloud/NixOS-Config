{ lib, ... }:
{
  options.rhen.rust.enable = lib.mkEnableOption "Rust development tools";
}
