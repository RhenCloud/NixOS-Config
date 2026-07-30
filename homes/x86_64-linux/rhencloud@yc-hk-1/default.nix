{ lib, ... }: {
  home.stateVersion = lib.mkDefault "26.11";
  programs.home-manager.enable = true;

  rhencloud = {
    fish.enable = true;
  };
}
