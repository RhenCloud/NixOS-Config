{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhen.fcitx5;

  # im-emoji-picker 是 Qt5 Widgets 插件，由 fcitx5 进程 dlopen 后在同进程内创建
  # QApplication。系统全局设置了 QT_QPA_PLATFORM=wayland，而 Qt5 的 wayland 平台
  # 插件（qtwayland）不在默认 QT_PLUGIN_PATH 里，缺失时 Qt 会 qFatal 直接终止
  # fcitx5。这里把 qt5 平台插件目录显式加进 QT_PLUGIN_PATH。
  qt5PluginPath = "${pkgs.qt5.qtwayland.bin}/${pkgs.qt5.qtbase.qtPluginPrefix}";
in
{
  options.rhen.fcitx5.enable = mkEnableOption "Fcitx5 input method";

  config = mkIf cfg.enable {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          qt6Packages.fcitx5-configtool
          qt6Packages.fcitx5-chinese-addons
          fcitx5-gtk
          # 当前使用 Rime/雾凇输入方案；移除 Mozc，避免其 Bazel/Qt 构建失败。
          librime
          librime-octagram
          librime-lua
          (fcitx5-rime.override {
            rimeDataPkgs = with pkgs; [ rime-data ];
          })
          inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.im-emoji-picker
        ];
        settings.addons."im-emoji-picker" = {
          globalSection = { };
          # fcitx::KeyListOption 序列化为独立 section，形如 [TriggerKey] 0=...
          sections.TriggerKey."0" = "Control+Alt+period";
        };
      };
    };

    environment.variables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      INPUT_METHOD = "fcitx";
      SDL_IM_MODULE = "fcitx";
      GLFW_IM_MODULE = "fcitx";
      QT_PLUGIN_PATH = [ qt5PluginPath ];
    };
  };
}
