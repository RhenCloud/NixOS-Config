{
  pkgs,
  lib,
  username,
  ...
}:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings = {

    # substituters = lib.mkForce [
    #   "https://hyprland.cachix.org"
    #   "https://mirror.sjtu.edu.cn/nix-channels/store"
    #   "https://mirrors.ustc.edu.cn/nix-channels/store"
    #   "https://cache.nixos.org"
    #   "https://nix-community.cachix.org"
    # ];
    # trusted-substituters = [
    #   "https://hyprland.cachix.org"
    #   "https://mirror.sjtu.edu.cn"
    #   "https://nix-community.cachix.org"
    #   "https://mirrors.ustc.edu.cn"
    # ];
    # trusted-public-keys = [
    #   "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    #   "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    #   "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    # ];

    max-jobs = "auto";
    builders-use-substitutes = true;
    auto-optimise-store = true;
  };

  zramSwap.enable = true;

  networking = {
    firewall.enable = false;
    networkmanager.enable = true;
  };

  services.mihomo = {
    enable = true;
    configFile = "/etc/mihomo/config.yaml";
    tunMode = true;
    webui = pkgs.metacubexd;
  };

  systemd.services.mihomo.serviceConfig.ExecStart = lib.mkForce ''
    ${pkgs.mihomo}/bin/mihomo -d /var/lib/mihomo -f /etc/mihomo/config.yaml
  '';
  systemd.services.mihomo.serviceConfig.User = lib.mkForce "root";
  systemd.services.mihomo.serviceConfig.Group = lib.mkForce "root";
  systemd.services.mihomo.serviceConfig.StateDirectory = lib.mkForce "mihomo";

  # systemd.user.services.mihomo-user = {
  #   enable = true;
  #   after = [ "network.target" ];
  #   wantedBy = [ "default.target" ];
  #   description = "Mihomo User Service";
  #   serviceConfig = {pcscd
  #     Type = "simple";
  #     ExecStart = ''${pkgs.mihomo}/bin/mihomo -d /home/${username}/.mihomo -f /home/${username}/config.yaml'';
  #   };
  # };

  services.dae = {
    enable = false;
    configFile = ./config.dae;
    assets = with pkgs; [
      v2ray-geoip
      v2ray-domain-list-community
    ];
    openFirewall = {
      enable = true;
      port = 1536;
    };
  };

  services.openssh.enable = true;
  services.pcscd.enable = true;
  services.pcscd.plugins = [ pkgs.ccid ];
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEMS=="usb", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="0030", GROUP="plugdev", MODE="0660"
  '';

  # Enable CUPS to print documents.
  services.printing.enable = true;

  time.timeZone = "Asia/Shanghai";
  i18n.supportedLocales = [
    "zh_CN.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
  ];
  i18n.defaultLocale = "zh_CN.UTF-8";

  services.udisks2.enable = true;

  xdg.menus.enable = true;
  xdg.mime.enable = true;

  services.dbus.enable = true;

  security.polkit.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
    configPackages = [ pkgs.xdg-desktop-portal-hyprland ];
    # config.common.default = "*";
    # xdgOpenUsePortal = true;
  };

  environment.etc."xdg/menus/applications.menu".source =
    "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
    "/share/zsh"
  ];

  programs.bash.enable = true;
  programs.fish.enable = true;
  programs.zsh.enable = true;

  programs.bash = {
    interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  users = {
    users.${username} = {
      home = "/home/${username}";
      shell = pkgs.bash;
      hashedPassword = "$y$j9T$9g/eMEwVjfWXhiR8M3UzN/$baNRWXMywZY8fsLIvC/1uPQxDJNksgpDRKyosat01Y9";
      isNormalUser = true; # 改为 isNormalUser，不是 isSystemUser
      group = username;
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
        "input"
      ];
    };
    groups.${username} = { };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false; # wheel 组无需密码
    extraRules = [
      {
        commands = [
          {
            command = "${pkgs.systemd}/bin/systemctl suspend";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.systemd}/bin/reboot";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.systemd}/bin/poweroff";
            options = [ "NOPASSWD" ];
          }
        ];
        groups = [ "wheel" ];
      }
    ];
  };

  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    git
    gnupg
    sops
    vim
    curl
    wget
    udisks
    neovim
    mpd
    daed
    gparted
    nixpkgs-fmt
    mihomo
    kdePackages.kleopatra
    pcsc-tools
    opensc
    usbutils
    tree
    nixd
    unzip
    ffmpeg
    fd
    nix-du
    nix-direnv
    deadnix
    nil

    # create a fhs environment by command `fhs`, so we can run non-nixos packages in nixos!
    (
      let
        base = pkgs.appimageTools.defaultFhsEnvArgs;
      in
      pkgs.buildFHSEnv (
        base
        // {
          name = "fhs";
          targetPkgs =
            pkgs:
            # pkgs.buildFHSEnv 只提供一个最小的 FHS 环境，缺少很多常用软件所必须的基础包
            # 所以直接使用它很可能会报错
            #
            # pkgs.appimageTools 提供了大多数程序常用的基础包，所以我们可以直接用它来补充
            (base.targetPkgs pkgs)
            ++ (with pkgs; [
              pkg-config
              ncurses
              libepoxy
              # 如果你的 FHS 程序还有其他依赖，把它们添加在这里
            ]);
          profile = "export FHS=1";
          runScript = "bash";
          extraOutputsToInstall = [ "dev" ];
        }
      )
    )
  ];
}
