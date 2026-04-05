{ pkgs, inputs, ... }:
{
  home.packages = with pkgs; [
    niri
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
