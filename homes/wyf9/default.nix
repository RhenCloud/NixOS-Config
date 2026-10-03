# wyf9 用户的共享 home-manager 配置
{ lib, ... }: {
  rhen.user.name = "wyf9";
  home.stateVersion = lib.mkDefault "26.11";
  programs.home-manager.enable = true;
  programs.man.enable = false;
}
