{ lib, ... }:
{
  programs.mango.enable = true;

  # GTK portal 处理 Settings/Inhibit，覆盖 mangowm 模块的默认值
  xdg.portal.config.mango = lib.mkForce {
    default = [ "gtk" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
    "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
    "org.freedesktop.impl.portal.Inhibit" = [ "gtk" ];
    "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
  };
}
