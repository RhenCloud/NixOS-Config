{ pkgs, ... }:
{
  xdg.configFile = {
    "mango" = {
      source = ./mango;
      recursive = true;
    };
  };
  # wayland.windowManager.mango = {
  #   enable = true;
  # };
  home.packages = with pkgs; [
    mango
  ];
}
