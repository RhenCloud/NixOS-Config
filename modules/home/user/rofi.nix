{ config, pkgs, lib, ... }:

{
  # home.file.".config/rofi" = {
  #   source = ./rofi;
  #   recursive = true;   # 递归整个文件夹
  #   executable = true;  # 将其中所有文件添加「执行」权限
  # };
  programs.rofi.enable = true;
}
