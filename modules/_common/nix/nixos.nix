{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.nix;
in
{
  options.rhencloud.nix.enable = mkEnableOption "Nix daemon settings";
  # 本地 nixcache 代理：把 GHCR 上的 OCI 二进制缓存（CI 构建产物）暴露为本地 substituter，
  # 并自动注册 substituters 与公钥。
  imports = [ inputs.nixcache.nixosModules.default ];
  config = mkIf cfg.enable {
    services.nixcache-proxy = {
      enable = true;
      repo = "rhencloud/nixos-config";
      publicKey = "RhenCloud-NixOS-Config-1:N+sDXsxJE6wzn//Hw7ScFANjOPucZKmIsX012iJCJPo=";
    };

    nix.package = pkgs.lixPackageSets.stable.lix;

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      accept-flake-config = true;
      max-jobs = "auto";
      builders-use-substitutes = true;
      auto-optimise-store = false;
      trusted-users = [ "@wheel" ];
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
      trusted-substituters = lib.mkForce [
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
      # extra-trusted-public-keys 不会被 flake 的 nixConfig.trusted-public-keys 覆盖，
      # 确保 nix run 外部 flake 时 cache.nixos.org 等缓存始终可用。
      extra-trusted-public-keys = [
        "rhencloud.cachix.org-1:ufAOdWG5R+cdEwikK58DG41wK6VrSVKwaSgnXxZ+D+E="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.nixos.org-1:6NCHdD59X431o0gWypQtVrp8bzFM4q3kncrKNSStQ5s="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    # 构建沙箱内需要 DNS 解析（VSCode、WeChat 等包需要下载）
    nix.settings.extra-sandbox-paths = [ "/etc/resolv.conf" ];

    systemd.services.nix-daemon.serviceConfig.Environment = [
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
