{
  pkgs,
  username,
  stateVersion,
  ...
}:

{
  # 注意修改这里的用户名与用户目录
  home.username = username;
  # home.homeDirectory = lib.mkForce "/home/${username}";
  home.homeDirectory = "/home/${username}";

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "$HOME/Desktop";
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    publicShare = "$HOME/Public";
    templates = "$HOME/Templates";
    videos = "$HOME/Videos";
  };

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
    ./core
    ./desktop
    ./service
    ./dev
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
    eza
    nixfmt
    keymapper
    wemeet
    qbittorrent
    blender
    aliyunpan
    splayer
    sequoia-chameleon-gnupg
    gnupg
    (writeShellScriptBin "gpg-card-ssh-pubkey" ''
      set -euo pipefail
      if [ "$#" -ne 1 ]; then
        echo "Usage: gpg-card-ssh-pubkey <OPENPGP_FINGERPRINT>" >&2
        exit 1
      fi

      gpg --export-ssh-key "$1"
    '')
    # (vivaldi.override {
    #   proprietaryCodecs = true;
    #   enableWidevine = true;
    # })
  ];

  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    extensions = [
      "bgnkhhnnamicmpeenaelnjfhikgbkllg" # AdGuard
      "ndcooeababalnlpkfedmmbbbgkljhpjf" # 脚本猫
      "lildghglkgcoanblbmenbefhnhifghjj" # BewlyBewly! Ave Mujica
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "jlgkpaicikihijadgifklkbpdajbkhjo" # crxMouse
    ];
    # commandLineArgs = [
    #   "--disable-features=WebRtcAllowInputVolumeAdjustment"
    # ];
  };

  programs.vscode = {
    enable = true;
    # package = pkgs.vscode.fhs;
  };

  # git 相关配置
  programs.git = {
    enable = true;
    signing = {
      signByDefault = true;
      format = "openpgp";
    };
    settings = {
      gpg.program = "${pkgs.gnupg}/bin/gpg";
      commit.gpgsign = true;
      tag.gpgSign = true;
      init.defaultBranch = "main";
      user = {
        name = "RhenCloud";
        email = "i@rhen.cloud";
        signingKey = "REDACTED-59acd1c2";
      };
    };
  };

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    enableScDaemon = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-qt;
    defaultCacheTtl = 1800;
    maxCacheTtl = 7200;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      identityAgent = "~/.gnupg/S.gpg-agent.ssh";
    };
  };

  home.file.".gnupg/scdaemon.conf".text = ''
    disable-ccid
    pcsc-shared
  '';

  programs.obs-studio = {
    enable = true;

    # optional Nvidia hardware acceleration
    package = (
      pkgs.obs-studio.override {
        cudaSupport = true;
      }
    );

    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vaapi # optional AMD hardware acceleration
      obs-gstreamer
      obs-vkcapture
    ];
  };

  home.file.".wakatime.cfg".text = ''
    [settings]
    api_url = https://hackatime.hackclub.com/api/hackatime/v1
    api_key = REDACTED-0d4ad3f0
    heartbeat_rate_limit_seconds = 30
  '';

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
