{ pkgs, inputs, ... }:
{
  # imports = [
  #   inputs.niri.homeModules.config
  # ];

  programs.niri = {
    enable = true;
    package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
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
