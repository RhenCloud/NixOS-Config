{ pkgs, ... }:
{
  xdg.menus.enable = true;
  xdg.mime.enable = true;

  # https://niri-wm.github.io/niri/Important-Software.html#portals
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      # GNOME portal: Niri 下 ScreenCast 必需
      xdg-desktop-portal-gnome
      # Hyprland portal: Screenshot / ScreenCast / GlobalShortcuts / RemoteDesktop
      xdg-desktop-portal-hyprland
      # GTK portal: FileChooser 及其他基本接口
      # 由 wayland-session 模块自动添加，UseIn 补丁在 overlays/portal-gtk 中全局覆盖
    ];

    # niri 和 Hyprland 的 portal 配置
    configPackages = [ pkgs.niri pkgs.hyprland ];

    # 明确指定各桌面环境的 portal 后端偏好
    # - Niri: gnome 提供 ScreenCast（niri 官方推荐）
    # - Hyprland: hyprland 提供 ScreenCast
    config = {
      hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
      niri = {
        default = [ "gnome" "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
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
