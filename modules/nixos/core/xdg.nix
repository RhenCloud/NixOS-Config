{ pkgs, ... }:
{
  xdg.menus.enable = true;
  xdg.mime.enable = true;

  # https://niri-wm.github.io/niri/Important-Software.html#portals
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      # GNOME portal: screencasting 必需
      xdg-desktop-portal-gnome
      # Hyprland portal: Screenshot / ScreenCast / GlobalShortcuts
      xdg-desktop-portal-hyprland
      # GTK portal 由 wayland-session 模块自动添加（hyprland + niri 均导入）
      # UseIn 补丁在 overlays/portal-gtk 中全局覆盖
    ];

    # niri 和 Hyprland 的 portal 配置
    configPackages = [ pkgs.niri pkgs.hyprland ];

    # 明确指定各桌面环境的 portal 后端偏好
    config = {
      common = {
        default = [ "hyprland" "gtk" "gnome" ];
      };
      hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
      niri = {
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };

    # 使 xdg-open 通过 portal 打开程序
    xdgOpenUsePortal = true;
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
