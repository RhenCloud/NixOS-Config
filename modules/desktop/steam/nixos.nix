{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhen.steam;
in
{
  options.rhen.steam.enable = mkEnableOption "Steam";

  config = mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };

    environment.systemPackages = with pkgs; [
      steam-run
    ];
  };
}
