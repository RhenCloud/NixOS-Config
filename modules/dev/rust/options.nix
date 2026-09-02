{ lib, ... }:
{
  options.rhencloud.rust.enable = lib.mkEnableOption "Rust development tools";
}
