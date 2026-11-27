{
  lib,
  ...
}:
with lib;
{
  options.rhen.qqWaylandFix = {
    enable = mkEnableOption "linuxqq-wayland-fix（修复 Wayland 下 QQ 的屏幕共享、剪贴板与截图）";

    qq = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        被修复的 QQ 包，写入启动器的 `QQ_WAYLAND_FIX_QQ`。

        保持 null 时由 NixOS 侧的 `programs.linuxqq-wayland-fix.qq` 决定；
        设为桌面 chat 模块的 `qq` 封装后，修复库接管的是带 fcitx 环境的
        启动脚本，输入法不丢失。
      '';
    };
  };
}
