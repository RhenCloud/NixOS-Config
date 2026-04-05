{ ... }:

{
  # i18n.inputMethod = {
  #   enable = true;
  #   type = "fcitx5";
  #   fcitx5 = {
  #     waylandFrontend = true;
  #     addons = with pkgs; [
  #       qt6Packages.fcitx5-configtool
  #       qt6Packages.fcitx5-chinese-addons
  #       fcitx5-gtk
  #       librime-octagram
  #       librime-lua
  #       (fcitx5-rime.override {
  #         rimeDataPkgs = [
  #           rime-data
  #         ];
  #       })
  #     ];
  #   };
  # };


  # 将本地的 rime 配置链接到 ~/.local/share/fcitx5/rime
  # fcitx5-rime 会优先读取此目录下的用户配置
  home.file.".local/share/fcitx5" = {
    source = ./fcitx5;
    recursive = true; # 递归整个文件夹，这样 rime 可以在目录下创建 build 等文件夹
  };
}
