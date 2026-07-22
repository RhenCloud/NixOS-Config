{ pkgs, inputs, ... }:
let
  mousePassthroughPatch = ../../../../patches/niri/mouse-passthrough.patch;
  pinPatch = ../../../../patches/niri/pin.patch;

  niri-patched = (inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable).overrideAttrs (old: {
    patches = (old.patches or []) ++ [ mousePassthroughPatch pinPatch ];
  });
in
{
  # imports = [
  #   inputs.niri.homeModules.config
  # ];

  programs.niri = {
    enable = true;
    package = niri-patched;
  };

  home.packages = [
    inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.xwayland-satellite-unstable
    pkgs.nirius
    # inputs.piri.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  xdg.configFile = {
    "niri" = {
      source = ./niri;
    };
    "niri_tweaks" = {
      source = inputs.niri_tweaks;
    };
  };

  programs.piri = {
    enable = true;
    enableFishIntegration = true;
    package = inputs.piri.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
