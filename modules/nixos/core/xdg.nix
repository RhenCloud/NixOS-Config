{ pkgs, ... }:
{
  xdg.menus.enable = true;
  xdg.mime.enable = true;

  # https://niri-wm.github.io/niri/Important-Software.html#portals
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk   # 默认后备，实现文件选择器等基本功能
      xdg-desktop-portal-gnome # screencasting 必需的 portal
    ];
    configPackages = [ pkgs.niri ];
  };

  environment.etc."xdg/menus/applications.menu".source =
    "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

  environment.pathsToLink = [
    "/share/applications"
    "/share/glib-2.0/schemas"
    "/share/xdg-desktop-portal"
    "/share/zsh"
  ];
}
