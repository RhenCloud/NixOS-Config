{
  description = "RhenCloud NixOS";

  nixConfig = {
    # extra-substituters = [
    #   # "s3://hi168-h5hv6zw90zf-sslnc1b0-s/nix-cache?endpoint=https://s3.hi168.com&region=auto"
    #   "https://yazi.cachix.org"
    # ];
    # extra-trusted-substituters = [
    #   # "s3://hi168-h5hv6zw90zf-sslnc1b0-s/nix-cache?endpoint=https://s3.hi168.com&region=auto"
    #   "https://yazi.cachix.org"
    # ];
    substituters = [
      # "https://cache.rhen.cloud"
      "https://rhencloud.cachix.org"
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
      # "https://cache.rhen.cloud"
      "https://rhencloud.cachix.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
      "https://noctalia.cachix.org"
      "https://niri.cachix.org"
      "https://vicinae.cachix.org"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
    ];
    extra-trusted-public-keys = [
      "rhencloud.cachix.org-1:ufAOdWG5R+cdEwikK58DG41wK6VrSVKwaSgnXxZ+D+E="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.nixos.org-1:6NCHdD59X431o0gWypQtVrp8bzFM4q3kncrKNSStQ5s="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "yazi.cachix.org-1:Dcdz63NZ5HpCDB+C1i3W6S3Gx2JBHaVNYh5MmiEXZo4="
    ];
  };

  inputs = {
    # ── 框架 ────────────────────────────────────────────
    snowveil = {
      url = "github:SnowveilOrg/Snowveil";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    flake-schemas = {
      url = "github:DeterminateSystems/flake-schemas";
    };

    # ── 频道 / 基础 ────────────────────────────────────
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # ── 统一 follow nixpkgs 的子 flake ─────────────────
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-latest = {
      url = "github:noctalia-dev/noctalia-shell/v5.0.0-beta.3";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    umbriel = {
      url = "github:noctalia-dev/umbriel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # lucy = {
    #   url = "github:RhenCloud/lucy";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
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
      # 临时锁定到 PR #1853，修复 nixpkgs 移除 libdisplay-info_0_2 后构建失败
      # 上游合并后可移除此固定（TODO: niri-flake release）
      url = "github:sodiboo/niri-flake/7e196a5ce0bf209d3aca844bb31edce5284d6484";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-shot = {
      url = "github:RhenCloud/niri-shot";
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
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr = {
      url = "github:ogulcancelik/herdr/v0.8.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jailed-agents = {
      url = "github:andersonjoseph/jailed-agents";
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

    # ── 其它 flake 输入 ────────────────────────────────
    # siiway-cli = {
    #   url = "github:siiway/siiway-cli";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    siiway-oc-plugin = {
      url = "github:SiiWay/VoidSwitch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    nixos-ai-skill = {
      url = "github:marceloeatworld/nixos-ai-skill";
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
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fast-nix-gc = {
      url = "github:Mic92/fast-nix-gc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sleepy = {
      url = "github:sleepy-project/sleepy/6babc99";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      systems = [ "x86_64-linux" ];
      # myPkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    in
    inputs.snowveil.lib.mkFlake {
      inherit inputs systems;

      # nixpkgs.overlays = [
      #   (final: prev: {
      #     gcc = prev.gcc14;
      #     gcc_latest = prev.gcc14;
      #   })
      # ];

      nixpkgs.config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "electron-39.8.10"
          "pnpm-9.15.9"
          "pnpm-10.29.2"
        ];
      };

      outputs = {
        extra = import ./flake/extra-outputs.nix { inherit inputs; };

        # 自动生成所有主机和 Home Manager 的求值检查
        eval = {
          hosts = true;
          homes = true;
        };

        diagnostics = {
          discovery = true;
          moduleGraph = true;
          perHostModuleGraph = false;
          doctor = true;
          expectedScaffold = true;
          moduleCoverage = true;
        };

        homes.standalone = false;

        # 防止目录重构或过滤规则变化时静默丢失关键 outputs。
        expected = {
          mode = "exact";
          hosts = [
            "nixos-desktop"
            "nixos-homeserver"
            "yc-hk-1"
          ];
          homes = [
            "advan10@yc-hk-1"
            "rhencloud@nixos-desktop"
            "rhencloud@nixos-homeserver"
            "rhencloud@yc-hk-1"
            "wyf9@yc-hk-1"
          ];
          packages = [
            "aicommits"
            "bt-iso-enable"
            "deploy-rs"
            "herdr-mobile-relay"
            "herdr-plus"
            "herdr-reviewr"
            "herdr-sidebar"
            "herdr-spreader"
            "herdr-tab-rename"
            "herdr-window-title-sync"
            "herdr-worktrunk"
            "jailed-pi"
            "opencode-zh-cn"
            "rime-keytao"
            "sandbox"
            "zed-globalization"
          ];
          apps = [
            "build"
            "deploy"
            "sandbox"
            "switch"
            "test"
            "vm"
          ];
          checks = [
            "deadnix"
            "deploy-nodes-schema"
            "formatting"
            "secrets"
            "statix"
          ];
          devShells = [
            "default"
            "python"
          ];
          formatter = [ "x86_64-linux" ];
          overlays = [
            "mexkey3-ccid"
            "musicfox"
            "niri"
            "portal-gtk"
            "waylyrics"
            "wechat"
          ];
          nixosModules = [
            "_common.bluetooth"
            "_common.boot"
            "_common.cloudflared"
            "_common.display-managers"
            "_common.docker"
            "_common.easytier"
            "_common.env"
            "_common.externals"
            "_common.fcitx5"
            "_common.fonts"
            "_common.identity"
            "_common.impermanence"
            "_common.kernel"
            "_common.locale"
            "_common.mihomo"
            "_common.nix"
            "_common.nvidia"
            "_common.options"
            "_common.packages"
            "_common.podman"
            "_common.qemu"
            "_common.router"
            "_common.selector4nix"
            "_common.services"
            "_common.shells"
            "_common.sound"
            "_common.xdg"
            "desktop.avahi"
            "desktop.externals"
            "desktop.games"
            "desktop.gnome"
            "desktop.hyprland"
            "desktop.mangowm"
            "desktop.nemo"
            "desktop.packages"
            "desktop.roles"
            "desktop.steam"
            "desktop.sunshine"
            "desktop.thunar"
            "desktop.umbriel"
            "desktop.zen"
            "dev"
            "dev.aider"
            "dev.android"
            "dev.c"
            "dev.certs"
            "dev.emacs"
            "dev.golang"
            "dev.helix"
            "dev.java"
            "dev.nixvim"
            "dev.node"
            "dev.opencode"
            "dev.packages"
            "dev.pi"
            "dev.python"
            "dev.rust"
            "server.baota-probe"
            "server.beszel"
            "server.beszel-agent"
            "server.easytier"
            "server.frp"
            "server.gost"
            "server.mailer"
            "server.nextbridge"
            "server.oci-helper"
            "server.openlist"
            "server.pds"
            "server.postgresql"
            "server.roles"
            "server.rustdesk"
            "server.sleepy"
            "server.vaultwarden"
            "server.wyf9s-bot"
            "server.yysong"
            "system"
          ];
          homeModules = [
            "_common.browser"
            "_common.clipse"
            "_common.externals"
            "_common.fastfetch"
            "_common.fish"
            "_common.ghostty"
            "_common.git"
            "_common.herdr"
            "_common.hm-packages"
            "_common.hm-xdg"
            "_common.mpd"
            "_common.mprisence"
            "_common.options"
            "_common.siiway-opencode"
            "_common.sops"
            "_common.wallpapers"
            "_common.yazi"
            "desktop.base"
            "desktop.caelestia"
            "desktop.chat"
            "desktop.externals"
            "desktop.fcitx5"
            "desktop.foot"
            "desktop.hyprland"
            "desktop.kitty"
            "desktop.mango"
            "desktop.misc"
            "desktop.musicfox"
            "desktop.nemo"
            "desktop.niri"
            "desktop.noctalia"
            "desktop.obs"
            "desktop.prismlauncher"
            "desktop.stylix"
            "desktop.theme"
            "desktop.tofi"
            "desktop.umbriel"
            "desktop.vicinae"
            "dev"
            "dev.aider"
            "dev.android"
            "dev.c"
            "dev.certs"
            "dev.emacs"
            "dev.golang"
            "dev.helix"
            "dev.java"
            "dev.nixvim"
            "dev.node"
            "dev.opencode"
            "dev.packages"
            "dev.pi"
            "dev.python"
            "dev.rust"
            "system"
          ];
          deploy = {
            present = true;
            nodes = [
              "nixos-desktop"
              "nixos-homeserver"
              "yc-hk-1"
            ];
          };
          images = { };
        };
      };
    };
}
