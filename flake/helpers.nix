{ lib, inputs }:
let
  root = toString inputs.self;

  it = inputs.import-tree;

  # 只收集各目录的 default.nix；目录内的 flat 文件由对应 default.nix 自行 import
  collectDefaultNix = it.filter (s: s == "/default.nix" || lib.hasSuffix "/default.nix" s);

  # 只收集根目录自身的 default.nix（子模块由父级 default.nix 以目录方式聚合）
  collectTopDefault = it.filter (s: s == "/default.nix");

  overlays = [
    (import "${root}/overlays/mexkey3-ccid/default.nix" { })
    (import "${root}/overlays/musicfox/default.nix" { })
    (import "${root}/overlays/niri/default.nix" { })
    (import "${root}/overlays/portal-gtk/default.nix" { })
    (import "${root}/overlays/waylyrics/default.nix" { })
    (import "${root}/overlays/wechat/default.nix" { })
  ];

  nixosModulesCore = [ (collectDefaultNix "${root}/modules/nixos/core") ];
  nixosModulesDesktop = [ (collectTopDefault "${root}/modules/nixos/desktop") ];
  nixosModulesServer = [ (collectTopDefault "${root}/modules/nixos/server") ];
  nixosModulesService = [ (collectTopDefault "${root}/modules/nixos/service") ];
  nixosModulesRouter = [ (collectTopDefault "${root}/modules/nixos/router") ];

  rolesModuleDesktop = [ (collectTopDefault "${root}/roles/desktop") ];
  rolesModuleServer = [ (collectTopDefault "${root}/roles/server") ];

  homeBase = "${root}/modules/home";

  homeCore = [ (collectDefaultNix "${homeBase}/core") ];
  homeService = [ (collectTopDefault "${homeBase}/service") ];
  homeDesktop = [ (collectDefaultNix "${homeBase}/desktop") ];
  homeDev = [ (collectDefaultNix "${homeBase}/dev") ];
  homeHerdr = [ (collectTopDefault "${homeBase}/herdr") ];

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
  serverHosts = [
    "yc-hk-1"
    "nixos-homeserver"
  ];
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
