{ lib, ... }: {
  home.stateVersion = lib.mkDefault "26.11";
  programs.home-manager.enable = true;
  programs.man.enable = false;

  rhencloud = {
    fish.enable = true;
    fastfetch.enable = true;
  };
}
