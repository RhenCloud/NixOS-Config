{ config
, lib
, pkgs
, inputs
, username
, stateVersion
, ...
}:

{
  # 注意修改这里的用户名与用户目录
  home.username = username;
  # home.homeDirectory = lib.mkForce "/home/${username}";
  home.homeDirectory = "/home/${username}";

  # 直接将当前文件夹的配置文件，链接到 Home 目录下的指定位置
  # home.file.".config/i3/wallpaper.jpg".source = ./wallpaper.jpg;

  # 递归将某个文件夹中的文件，链接到 Home 目录下的指定位置
  # home.file.".config/i3/scripts" = {
  #   source = ./scripts;
  #   recursive = true;   # 递归整个文件夹
  #   executable = true;  # 将其中所有文件添加「执行」权限
  # };

  # 直接以 text 的方式，在 nix 配置文件中硬编码文件内容
  # home.file.".xxx".text = ''
  #     xxx
  # '';

  # 设置鼠标指针大小以及字体 DPI
  xresources.properties = {
    "Xcursor.size" = 24;
    "Xft.dpi" = 96;
  };

  imports = [
    ./user
    ./secrets
    ./core
    ./desktop
    ./service
  ];

  # home.packages = with nurpkgs.repos.novel2430; [
  #   wechat-universal-bwrap
  # ];

  home.packages = with pkgs; [
    fzf
    sptk
    perl
    themechanger
    google-chrome
    networkmanager_dmenu
    eza
    nixfmt
    nil
    keymapper
    telegram-desktop
    qq
    wechat
    microsoft-edge
  ];

  programs.vscode = {
    enable = true;
    # package = pkgs.vscode.fhs;
  };

  programs.direnv = {
    enable = true;
  };

  # git 相关配置
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      user = {
        name = "Rhen";
        email = "i@rhen.cloud";
      };
    };
  };

  # home.activation.copyDesktopFiles = lib.hm.dag.entryAfter [ "installPackages" ] ''
  #   if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then

  #     if [ ! -d "${config.home.homeDirectory}/.local/share/applications" ]; then
  #       mkdir "${config.home.homeDirectory}/.local/share/applications"
  #     fi

  #     if [ -d "${config.home.homeDirectory}/.local/share/applications/nix" ]; then
  #       rm -rf "${config.home.homeDirectory}/.local/share/applications/nix"
  #     fi

  #     ln -sf "${config.home.homeDirectory}/.nix-profile/share/applications" \
  #       ${config.home.homeDirectory}/.local/share/applications/nix

  #   fi
  # '';

  home.stateVersion = stateVersion;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
