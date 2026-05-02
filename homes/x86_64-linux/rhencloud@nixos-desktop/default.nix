{ lib, ... }:
{
  home.stateVersion = lib.mkDefault "26.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.man.enable = false;
}
