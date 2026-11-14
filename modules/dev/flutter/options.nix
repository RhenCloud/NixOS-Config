{ lib, ... }:
{
  options.rhen.flutter.enable = lib.mkEnableOption "Flutter 与 Dart 开发工具链";
}
