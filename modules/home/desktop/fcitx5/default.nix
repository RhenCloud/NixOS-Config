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


  # 仅管理 fcitx5 主题配置，不接管整个目录以免干扰 rime
  home.file.".local/share/fcitx5/themes" = {
    source = ./fcitx5/themes;
    recursive = true;
  };

  # 星空键道6 输入方案
  programs.rime-keytao = {
    enable = true;
    rimeDataDir = ".local/share/fcitx5/rime";
  };
}
