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
    # 上游模块负责安装修复包与 QQ 本体，并把 QQ 路径写进启动器的
    # QQ_WAYLAND_FIX_QQ / QQ_WAYLAND_FIX_QQ_ROOT。
    #
    # 修复通过 LD_PRELOAD 向 QQ 注入四个小库，不修改 QQ 自身文件：
    #   libqq-wl-portal.so    屏幕共享 / 共享设备音频（走 portal + PipeWire）
    #   libqq-clipbridge.so   X11 与 Wayland 剪贴板双向桥接
    #   libqq-screenshot.so   截图防闪退
    #   libqq-borderfix.so    共享时隐藏全屏边框
    #
    # 屏幕共享走 portal 的 ScreenCast 接口，需要 xdg-desktop-portal
    #（由 rhen.xdg 提供，未启用时上游模块会发 warning）。
    programs.linuxqq-wayland-fix = {
      enable = true;
      # 默认（null）即 pkgs.qq；仅在显式指定时才覆盖，
      # 避免在 allowUnfree 关闭的求值下把 pkgs.qq 求值出来。
    }
    // optionalAttrs (cfg.qq != null) {
      qq = cfg.qq;
    };
  };
}
