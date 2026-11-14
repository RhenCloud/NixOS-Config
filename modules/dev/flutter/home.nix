{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhen.flutter;
in
{
  config = mkIf cfg.enable {
    # flutter 包自带 bin/dart（指向内部 cache/dart-sdk 的符号链接），
    # 因此不再单独安装 pkgs.dart，否则 bin/dart 会与之冲突。
    # Android 构建链（SDK/JDK/adb）与 ANDROID_HOME 已由
    # rhen.android 和 rhen.java 提供，此处不重复声明。
    home.packages = with pkgs; [
      flutter
      # Dart 生态辅助工具
      dart-sass
      # 管理 $ANDROID_HOME 下缺失的 SDK 组件（如 cmdline-tools）与 license
      sdkmanager

      flutter_rust_bridge_codegen
      cargo-expand
    ];
  };
}
