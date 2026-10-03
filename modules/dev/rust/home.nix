{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhen.rust;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      rustup
    ];
  };
}
