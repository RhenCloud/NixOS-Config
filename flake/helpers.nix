{ lib, inputs }:
let
  root = toString inputs.self;

  overlays = [
    (import "${root}/overlays/mexkey3-ccid/default.nix" { })
    (import "${root}/overlays/musicfox/default.nix" { })
    (import "${root}/overlays/niri/default.nix" { })
    (import "${root}/overlays/portal-gtk/default.nix" { })
    (import "${root}/overlays/waylyrics/default.nix" { })
    (import "${root}/overlays/wechat/default.nix" { })
  ];

  nixosModulesCore = [
    "${root}/modules/nixos/core/default.nix"
    "${root}/modules/nixos/core/impermanence/default.nix"
    "${root}/modules/nixos/core/mihomo/default.nix"
  ];
  nixosModulesDesktop = [
    "${root}/modules/nixos/desktop/default.nix"
  ];
  nixosModulesServer = [
    "${root}/modules/nixos/server/default.nix"
  ];
  nixosModulesService = [
    "${root}/modules/nixos/service/default.nix"
  ];
  nixosModulesRouter = [
    "${root}/modules/nixos/router/default.nix"
  ];

  rolesModuleDesktop = [ "${root}/roles/desktop/default.nix" ];
  rolesModuleServer = [ "${root}/roles/server/default.nix" ];

  homeBase = "${root}/modules/home";

  homeCore = [
    "${homeBase}/core/default.nix"
    "${homeBase}/core/fastfetch/default.nix"
    "${homeBase}/core/fish/default.nix"
    "${homeBase}/core/ghostty/default.nix"
    "${homeBase}/core/sops/default.nix"
    "${homeBase}/core/yazi/default.nix"
  ];
  homeService = [
    "${homeBase}/service/default.nix"
  ];
  homeDesktop = [
    "${homeBase}/desktop/base/default.nix"
    "${homeBase}/desktop/chat/default.nix"
    "${homeBase}/desktop/fcitx5/default.nix"
    "${homeBase}/desktop/foot/default.nix"
    "${homeBase}/desktop/hyprland/default.nix"
    "${homeBase}/desktop/kitty/default.nix"
    "${homeBase}/desktop/mango/default.nix"
    "${homeBase}/desktop/misc/default.nix"
    "${homeBase}/desktop/musicfox/default.nix"
    "${homeBase}/desktop/niri/default.nix"
    "${homeBase}/desktop/noctalia/default.nix"
    "${homeBase}/desktop/obs/default.nix"
    "${homeBase}/desktop/prismlauncher/default.nix"
    "${homeBase}/desktop/stylix/default.nix"
    "${homeBase}/desktop/theme/default.nix"
    "${homeBase}/desktop/tofi/default.nix"
    "${homeBase}/desktop/vicinae/default.nix"
  ];
  homeDev = [
    "${homeBase}/dev/default.nix"
    "${homeBase}/dev/aider/default.nix"
    "${homeBase}/dev/helix/default.nix"
    "${homeBase}/dev/nixvim/default.nix"
    "${homeBase}/dev/opencode/default.nix"
  ];
  homeHerdr = [
    "${homeBase}/herdr/default.nix"
  ];

  # 所有系统共用的 home 模块
  homeModules = homeCore ++ homeService ++ homeHerdr;

  optionsModule = "${root}/modules/options.nix";

  # 所有系统共用的 HM 基础设施
  essentialHomeModules = [
    optionsModule
    # inputs.lucy.homeManagerModules.default
    inputs.sops-nix.homeManagerModules.sops
    inputs.noctalia-v4.homeModules.default
    inputs.nix-index-database.homeModules.nix-index
    { nixpkgs.overlays = overlays; }
    ({ config, ... }: {
      nixpkgs.config.allowUnfree = config.my.allowUnfree;
      nixpkgs.config.permittedInsecurePackages = config.my.permittedInsecurePackages;
    })
    ({ config, ... }: {
      home.homeDirectory = "/home/${config.my.user.name}";
      home.username = config.my.user.name;
    })
  ];

  # 桌面端独有的本地 HM 模块
  desktopHomeModules = homeDesktop ++ homeDev;

  # 桌面端独有的外部 HM 模块（重型/纯桌面）
  desktopExtraHomeModules = [
    inputs.mangowm.hmModules.mango
    inputs.niri.homeModules.niri
    inputs.piri.homeManagerModules.default
    inputs.nixvim.homeModules.nixvim
    inputs.rime-keytao.homeManagerModules.default
    inputs.vicinae.homeManagerModules.default
    inputs.stylix.homeModules.stylix
  ];

  desktopHomeModulesFull = desktopHomeModules ++ desktopExtraHomeModules;

  desktopHosts = [ "nixos-desktop" ];
  serverHosts = [ "yc-hk-1" ];
in
{
  inherit
    root
    overlays
    nixosModulesCore
    nixosModulesDesktop
    nixosModulesServer
    nixosModulesService
    nixosModulesRouter
    rolesModuleDesktop
    rolesModuleServer
    homeModules
    optionsModule
    essentialHomeModules
    desktopHomeModules
    desktopExtraHomeModules
    desktopHomeModulesFull
    desktopHosts
    serverHosts
    ;
}
