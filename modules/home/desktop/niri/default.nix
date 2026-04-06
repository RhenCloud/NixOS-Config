{ pkgs, inputs, ... }:
{
  # imports = [
  #   inputs.niri.homeModules.config
  # ];

  nixpkgs.overlays = [ inputs.niri.overlays.niri ];
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
  };

  home.packages = with pkgs; [
    xwayland-satellite
    nirius
    # inputs.piri.packages.${pkgs.system}.default
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
  };
}
