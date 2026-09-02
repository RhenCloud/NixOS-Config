{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.rust;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      rustup
    ];
  };
}
