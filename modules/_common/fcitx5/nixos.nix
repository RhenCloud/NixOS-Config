{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhen.fcitx5;
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
        ];
      };
    };

    environment.variables = {
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      INPUT_METHOD = "fcitx";
      SDL_IM_MODULE = "fcitx";
      GLFW_IM_MODULE = "fcitx";
    };
  };
}
