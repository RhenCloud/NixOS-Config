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
    nixpkgs.overlays = [
      (_final: prev: {
        inherit (prev.lixPackageSets.stable)
          nixpkgs-review
          nix-eval-jobs
          nix-fast-build
          ;
      })
    ];

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
