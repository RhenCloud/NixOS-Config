{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhen.qqWaylandFix;
in
{
  config = mkIf cfg.enable {
    xdg.desktopEntries = {
      # 上游包会装一份 /run/current-system/sw/share/applications/
      # linuxqq-wayland-fix.desktop（名字「QQ（Wayland修复版）」）。
      # 这里用同名用户级条目把它隐藏：XDG 优先级下 ~/.local/share/applications
      # 覆盖系统目录，避免菜单里出现两个 QQ。
      "linuxqq-wayland-fix" = {
        name = "QQ（Wayland修复版）";
        comment = "已并入「QQ」入口，此处仅用于隐藏重复菜单项";
        exec = "linuxqq-wayland-fix %U";
        icon = "qq";
        terminal = false;
        noDisplay = true;
      };

      # 让原有「QQ」入口直接启动修复版启动器。
      # 启动器自己会 exec QQ_WAYLAND_FIX_QQ 指向的 QQ，并注入修复库；
      # 输入法依赖 _common.fcitx5 设置的系统级 GTK_IM_MODULE / QT_IM_MODULE，
      # 因此不再需要 chat 模块的 qq wrapper。
      qq = mkForce {
        name = "QQ";
        comment = "Tencent QQ（Wayland 屏幕共享、剪贴板与截图已修复）";
        exec = "linuxqq-wayland-fix %U";
        icon = "qq";
        terminal = false;
        categories = [
          "Network"
          "InstantMessaging"
          "Chat"
        ];
      };
    };
  };
}
