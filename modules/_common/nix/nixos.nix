{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhen.nix;
in
{
  options.rhen.nix.enable = mkEnableOption "Nix daemon settings";
  # 本地 nixcache 代理：把 GHCR 上的 OCI 二进制缓存（CI 构建产物）暴露为本地 substituter，
  # 并自动注册 substituters 与公钥。
  imports = [ inputs.nixcache.nixosModules.default ];
  config = mkIf cfg.enable {
    services.nixcache-proxy = {
      enable = true;
      repo = "rhencloud/nixos-config";
      publicKey = "RhenCloud-NixOS-Config-1:N+sDXsxJE6wzn//Hw7ScFANjOPucZKmIsX012iJCJPo=";

      # 上游 nixcache-oci 的 buildRustPackage 未声明 pkg-config、zstd 与 aws-lc，
      # 导致 zstd-sys 探测 libzstd 失败，以及 aws-lc-sys 在
      # AWS_LC_SYS_USE_SYSTEM=1 下找不到系统 AWS-LC。
      package =
        (import "${inputs.nixcache}/default.nix" { inherit pkgs; }).cache-proxy.overrideAttrs
          (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.pkg-config ];
            buildInputs = (old.buildInputs or [ ]) ++ [
              pkgs.zstd
              pkgs.aws-lc
            ];
          });
    };

    nix.package = pkgs.lixPackageSets.stable.lix;

    nix.settings = {
      eval-cache = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      accept-flake-config = true;
      max-jobs = "auto";
      builders-use-substitutes = true;
      # cache.nixos.org 在 25 并发下会被 Fastly 限速排队，
      # 降低并发并放宽超时可显著减少大量 narinfo 的超时重试。
      http-connections = 8;
      connect-timeout = 60;
      download-attempts = 10;
      auto-optimise-store = false;
      trusted-users = [ "@wheel" ];
      substituters = [
        # "https://cache.rhen.cloud"
        # "https://rhencloud.cachix.org"
        # 国内镜像实测最快，放在前面优先命中。
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
        "https://noctalia.cachix.org"
        "https://niri.cachix.org"
        "https://vicinae.cachix.org"
      ];
      trusted-substituters = lib.mkForce [
        # "https://cache.rhen.cloud"
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
      # extra-trusted-public-keys 不会被 flake 的 nixConfig.trusted-public-keys 覆盖，
      # 确保 nix run 外部 flake 时 cache.nixos.org 等缓存始终可用。
      extra-trusted-public-keys = [
        # "rhencloud.cachix.org-1:ufAOdWG5R+cdEwikK58DG41wK6VrSVKwaSgnXxZ+D+E="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.nixos.org-1:6NCHdD59X431o0gWypQtVrp8bzFM4q3kncrKNSStQ5s="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    # 构建沙箱内需要 DNS 解析（VSCode、WeChat 等包需要下载）。
    # relaxed 允许 fixed-output fetcher（例如 Cargo 的 Git 依赖）联网，
    # 同时保留普通构建的沙箱隔离；否则无法获取 Smithay 等 Git 依赖。
    nix.settings = {
      sandbox = "relaxed";
      extra-sandbox-paths = [ "/etc/resolv.conf" ];
    };

    # 仅在本机实际运行 mihomo 时才让 nix-daemon 走本地代理，
    # 否则 127.0.0.1:7890 无监听会导致所有 substituter 下载失败。
    systemd.services.nix-daemon.serviceConfig.Environment =
      lib.optionals (config.rhen.services.mihomo.enable or false)
        [
          "http_proxy=http://127.0.0.1:7890"
          "https_proxy=http://127.0.0.1:7890"
          "all_proxy=http://127.0.0.1:7890"
        ];

    nix.gc = {
      automatic = lib.mkDefault false;
    };

    # 用 fast-nix-gc 替换内置 nix-store --gc（快 25-180 倍）
    services.fast-nix-gc = {
      enable = true;
      automatic = true;
      dates = "weekly";
      deleteOlderThan = "7d";
    };
    services.fast-nix-optimise = {
      enable = true;
      automatic = true;
      dates = "04:15";
    };
  };
}
