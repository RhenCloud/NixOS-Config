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
    substituters = [
      # "https://rhencloud.cachix.org"
      "https://hyprland.cachix.org"
      # "https://nix-community.cachix.org"
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
      # "https://nix-community.cachix.org"
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
      # "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    # home-manager, used for managing user configuration
    home-manager = {
      # url = "https://gh-proxy.com/github.com/nix-community/home-manager/archive/master.tar.gz";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell/v4.7.7";
      # url = "https://gh-proxy.com/github.com/noctalia-dev/noctalia-shell/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    piri.url = "github:RhenCloud/piri";

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    siiway-cli = {
      url = "https://gh-proxy.com/github.com/siiway/siiway-cli/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    aagl.url = "github:ezKEa/aagl-gtk-on-nix";

    # mango = {
    #   url = "github:DreamMaoMao/mango";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    niri = {
      url = "github:sodiboo/niri-flake";
      # inputs.niri-unstable.url = "github:niri-wm/niri/wip/branch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri_tweaks = {
      url = "github:heyoeyo/niri_tweaks";
      flake = false;
    };

    liteloaderqqnt = {
      url = "github:LiteLoaderQQNT/LiteLoaderQQNT/1.4.1";
      flake = false;
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
    };

    cloud-pyprland = {
      url = "github:RhenCloud/cloud-pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";

    # agenix.url = "github:ryntm/agenix";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:ogulcancelik/herdr/v0.7.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rime-keytao = {
      url = "github:xkinput/KeyTao";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    siiway-oc-plugin.url = "git+ssh://git@github.com/siiway/VoidSwitch";

    opencode-worktree = {
      url = "github:kdcokenny/opencode-worktree";
      flake = false;
    };
  };

  outputs = inputs: import ./flake/outputs.nix inputs;
}
