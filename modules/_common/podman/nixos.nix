{
  config,
  lib,
  pkgs,
  primaryUser,
  ...
}:
with lib;
let
  cfg = config.rhencloud.podman;
in
{
  options.rhencloud.podman.enable = mkEnableOption "Podman (rootless)";

  config = mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };

    users.users.${primaryUser}.extraGroups = [ "podman" ];
  };
}
