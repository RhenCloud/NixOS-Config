{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.file.".config/fastfetch" = {
    source = ../config/fastfetch;
    recursive = true; # 递归整个文件夹
    # executable = true; # 将其中所有文件添加「执行」权限
  };
  programs.fastfetch.enable = true;
}
