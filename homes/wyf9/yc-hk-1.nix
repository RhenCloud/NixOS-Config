{ lib, ... }: {
  my.user.name = "wyf9";
  home.stateVersion = lib.mkDefault "26.11";
  programs.home-manager.enable = true;
  programs.man.enable = false;
}
