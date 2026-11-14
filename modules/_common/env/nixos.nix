{ config, lib, ... }:
with lib;
let
  cfg = config.rhen.env;
in
{
  options.rhen.env.enable = mkEnableOption "system environment variables";

  config = mkIf cfg.enable {
    # 仅在本机实际运行 mihomo 时才注入代理变量，否则 127.0.0.1:7890 无人监听，
    # 会让 podman、curl 等所有走环境变量的工具连接失败。
    environment.sessionVariables =
      optionalAttrs (config.rhen.services.mihomo.enable or false) {
        https_proxy = "http://127.0.0.1:7890";
        http_proxy = "http://127.0.0.1:7890";
        all_proxy = "http://127.0.0.1:7890";
      }
      // {
        LANG = "zh_CN.UTF-8";

        # 与 home 层 modules/desktop/theme 保持一致：
        # qtct 平台主题（读 qt5ct/qt6ct 配置），样式交给 Kvantum（Dracula）
        QT_QPA_PLATFORMTHEME = "qtct";
        QT_STYLE_OVERRIDE = "kvantum";

        NIXOS_OZONE_WL = "1";
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
    };
  };
}
