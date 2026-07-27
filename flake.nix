{
  description = "RhenCloud NixOS";

  nixConfig = {
    extra-substituters = [
      "s3://hi168-h5hv6zw90zf-sslnc1b0-s/nix-cache?endpoint=https://s3.hi168.com&region=auto"
      "https://yazi.cachix.org"
    ];
    extra-trusted-substituters = [
      "s3://hi168-h5hv6zw90zf-sslnc1b0-s/nix-cache?endpoint=https://s3.hi168.com&region=auto"
      "https://yazi.cachix.org"
    ];
    substituters = [
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
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://mirror.sjtu.edu.cn"
      "https://mirrors.ustc.edu.cn"
    ];
    trusted-public-keys = [
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
    # ── 框架 ────────────────────────────────────────────
    flake-parts.url = "github:hercules-ci/flake-parts";

    # ── 频道 / 基础 ────────────────────────────────────
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    # ── 统一 follow nixpkgs 的子 flake ─────────────────
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-v4 = {
      url = "github:noctalia-dev/noctalia-shell/v4.7.7";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-latest = {
      url = "github:noctalia-dev/noctalia-shell/v5.0.0-beta.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lucy = {
      url = "github:RhenCloud/lucy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    piri = {
      url = "github:RhenCloud/piri";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mangowm = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cloud-pyprland = {
      url = "github:RhenCloud/cloud-pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    yazi = {
      url = "github:sxyazi/yazi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── 无 nixpkgs input 的输入（tarball / 未验证） ──
    siiway-cli.url = "https://gh-proxy.com/github.com/siiway/siiway-cli/archive/main.tar.gz";
    siiway-oc-plugin.url = "github:SiiWay/VoidSwitch";

    # ── flake = false（纯数据源，无 flake.nix） ────────
    niri_tweaks = {
      url = "github:heyoeyo/niri_tweaks";
      flake = false;
    };
    liteloaderqqnt = {
      url = "github:LiteLoaderQQNT/LiteLoaderQQNT/1.4.1";
      flake = false;
    };
    opencode-worktree = {
      url = "github:kdcokenny/opencode-worktree";
      flake = false;
    };
    yazi-flavors = {
      url = "github:yazi-rs/flavors";
      flake = false;
    };
    selector4nix = {
      url = "github:StarryReverie/selector4nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        ./flake/pkgs.nix
        ./flake/nixos.nix
        ./flake/home-manager.nix
        ./flake/packages.nix
        ./flake/devshells.nix
        ./flake/lib.nix
      ];

      # Live CD 配置
      flake.nixosConfigurations.iso = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./iso.nix
          inputs.impermanence.nixosModules.impermanence
        ];
      };
    };
}
