_:
{
  environment.sessionVariables = {
    LANG = "zh_CN.UTF-8";

    https_proxy = "http://127.0.0.1:7890";
    http_proxy = "http://127.0.0.1:7890";
    all_proxy = "http://127.0.0.1:7890";

    QT_QPA_PLATFORMTHEME = "gtk3";
    QT_STYLE_OVERRIDE = "kvantum";

    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    GDK_BACKEND = "wayland";
    GTK_USE_PORTAL = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    MOZ_ENABLE_WAYLAND = "1";

    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
  };

  environment.variables = {
    EDITOR = "code";
    MOZ_ENABLE_WAYLAND = "1";
    # GTK_IM_MODULE = "fcitx";
    # QT_IM_MODULE = "fcitx";
    # XMODIFIERS = "@im=fcitx";
    # INPUT_METHOD = "fcitx";
    # GLFW_IM_MODULE = "fcitx";
  };
}
