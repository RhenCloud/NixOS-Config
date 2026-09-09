{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.nix;
in
{
  options.rhencloud.nix.enable = mkEnableOption "Nix daemon settings";
  config = mkIf cfg.enable {
    nix.package = pkgs.lixPackageSets.stable.lix;

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      accept-flake-config = true;
      max-jobs = "auto";
      builders-use-substitutes = true;
      auto-optimise-store = true;
      trusted-users = [ "@wheel" ];
      # 缓存源配置，与 flake.nix 保持同步
      trusted-public-keys = [
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
