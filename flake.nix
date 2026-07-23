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
      "http://127.0.0.1:5496/"
    ];
    trusted-substituters = [
      "http://127.0.0.1:5496/"
    ];
    trusted-public-keys = [ ];
  };

  # ── 所有 flake 输入 ──────────────────────────────────────
  #
  # 规则：绝大多数子 flake 的 inputs.nixpkgs 都统一 follow 我们的
  # nixpkgs-unstable，确保所有模块依赖同一套 nixpkgs 版本，避免求值
  # 不一致。非 flake 输入（flake=false / tarball）没有 nixpkgs input，
  # 拆到下方单独列出。

  inputs = {
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
    snowfall-lib = {
      url = "github:snowfallorg/lib";
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
  };

  outputs = inputs: import ./flake/outputs.nix inputs;
}
