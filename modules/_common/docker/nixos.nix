{
  config,
  lib,
  pkgs,
  primaryUser,
  ...
}:
with lib;
let
  cfg = config.rhen.docker;
in
{
  options.rhen.docker.enable = mkEnableOption "Docker";

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      package = pkgs.docker;
      enableOnBoot = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };

    users.users.${primaryUser}.extraGroups = [ "docker" ];

    environment.systemPackages = with pkgs; [
      docker-compose
    ];
  };
}
