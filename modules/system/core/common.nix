{ pkgs
, lib
, username
, ...
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

  networking = {
    firewall.enable = false;
    networkmanager.enable = true;
  };

  services.mihomo = {
    enable = true;
    configFile = "/home/${username}/config.yaml";
    # configFile = "/home/${username}/.config/mihomo/config.yaml";
    tunMode = true;
  };

  services.openssh.enable = true;

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
          { command = "${pkgs.systemd}/bin/systemctl suspend"; options = [ "NOPASSWD" ]; }
          { command = "${pkgs.systemd}/bin/reboot"; options = [ "NOPASSWD" ]; }
          { command = "${pkgs.systemd}/bin/poweroff"; options = [ "NOPASSWD" ]; }
        ];
        groups = [ "wheel" ];
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    udisks
    neovim
    mpd
    # clash-nyanpasu
    # clash-verge-rev
    nixpkgs-fmt
  ];
}
