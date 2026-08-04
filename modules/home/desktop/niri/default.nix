{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.hm-niri;

  mousePassthroughPatch = ../../../../patches/niri/mouse-passthrough.patch;
  pinPatch = ../../../../patches/niri/pin.patch;

  niri-patched =
    inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable.overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [
          mousePassthroughPatch
          pinPatch
        ];
      });
in
{
  options.rhencloud.hm-niri.enable = mkEnableOption "Niri (HM)";

  config = mkIf cfg.enable {
    programs.niri = {
      enable = true;
      package = niri-patched;
    };

    home.packages = [
      inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.xwayland-satellite-unstable
      pkgs.nirius
    ];
    xdg.configFile = {
      "niri/autostart.kdl".source = ./niri/autostart.kdl;
      "niri/config.kdl".source = ./niri/config.kdl;
      "niri/dracula.kdl".source = ./niri/dracula.kdl;
      "niri/env.kdl".source = ./niri/env.kdl;
      "niri/input.kdl".source = ./niri/input.kdl;
      "niri/keys.kdl".source = ./niri/keys.kdl;
      "niri/rule.kdl".source = ./niri/rule.kdl;
      "niri/piri.toml".source = config.lib.file.mkOutOfStoreSymlink "/run/secrets/templates/piri.toml";
      "niri_tweaks" = {
        source = inputs.niri_tweaks;
      };
    };

    programs.piri = {
      enable = true;
      enableFishIntegration = true;
      package = inputs.piri.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
  };
}
