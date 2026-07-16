{
  description = "NixOS configuration";

  nixConfig = {
    # extra-substituters = [
    #   "https://mirrors.ustc.edu.cn/nix-channels/store"
    #   "https://mirror.sjtu.edu.cn/nix-channels/store"
    # ];
    # extra-trusted-substituters = [
    #   "https://mirror.sjtu.edu.cn"
    #   "https://mirrors.ustc.edu.cn"
    # ];
    extra-substituters = [
      "https://yazi.cachix.org"
    ];
    extra-trusted-substituters = [
      "https://yazi.cachix.org"
    ];
    substituters = [
      # "https://rhencloud.cachix.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
      "https://noctalia.cachix.org"
      "https://niri.cachix.org"
      "https://vicinae.cachix.org"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
    ];
    trusted-substituters = [
      # "https://rhencloud.cachix.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://mirror.sjtu.edu.cn"
      "https://mirrors.ustc.edu.cn"
    ];
    trusted-public-keys = [
      # "rhencloud.cachix.org-1:ufAOdWG5R+cdEwikK58DG41wK6VrSVKwaSgnXxZ+D+E="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "yazi.cachix.org-1:Dcdz63NZ5HpCDB+C1i3W6S3Gx2JBHaVNYh5MmiEXZo4="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    # nixpkgs.follows = "nixpkgs";

    # home-manager, used for managing user configuration
    home-manager.url = "github:nix-community/home-manager";

    nur.url = "github:nix-community/NUR";

    snowfall-lib.url = "github:snowfallorg/lib";

    noctalia.url = "github:noctalia-dev/noctalia-shell/v4.7.7";

    piri.url = "github:RhenCloud/piri";

    stylix.url = "github:nix-community/stylix";

    siiway-cli.url = "https://gh-proxy.com/github.com/siiway/siiway-cli/archive/main.tar.gz";

    aagl.url = "github:ezKEa/aagl-gtk-on-nix";

    # mango = {
    #   url = "github:DreamMaoMao/mango";

    niri.url = "github:sodiboo/niri-flake";

    niri_tweaks = {
      url = "github:heyoeyo/niri_tweaks";
      flake = false;
    };

    liteloaderqqnt = {
      url = "github:LiteLoaderQQNT/LiteLoaderQQNT/1.4.1";
      flake = false;
    };

    hyprland.url = "github:hyprwm/Hyprland";

    cloud-pyprland.url = "github:RhenCloud/cloud-pyprland";

    sops-nix.url = "github:Mic92/sops-nix";

    # agenix.url = "github:ryntm/agenix";

    zen-browser.url = "github:youwen5/zen-browser-flake";

    nvf.url = "github:notashelf/nvf";

    herdr.url = "github:ogulcancelik/herdr/v0.7.0";

    vicinae.url = "github:vicinaehq/vicinae";

    rime-keytao.url = "github:xkinput/KeyTao";

    siiway-oc-plugin.url = "github:SiiWay/VoidSwitch";

    opencode-worktree.url = "github:kdcokenny/opencode-worktree";

    nix-index-database.url = "github:nix-community/nix-index-database";

    yazi.url = "github:sxyazi/yazi";

    yazi-flavors = {
      url = "github:yazi-rs/flavors";
      flake = false;
    };
  };
  outputs = inputs: import ./flake/outputs.nix inputs;
}
