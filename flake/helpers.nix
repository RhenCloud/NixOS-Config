{ lib, inputs }:
let
  root = toString inputs.self;

  collectSubdirs = dir:
    let
      entries = builtins.readDir dir;
      dirs = lib.filterAttrs (_name: type: type == "directory") entries;
    in
      builtins.attrNames dirs;

  collectDefaultNix = dir:
    let
      entries = builtins.readDir dir;
      dirs = lib.filterAttrs (_name: type: type == "directory") entries;
      rootDefault = lib.optional (builtins.pathExists "${dir}/default.nix") "${dir}/default.nix";
    in
      rootDefault ++ lib.flatten (
        lib.mapAttrsToList (name: _:
          let sub = "${dir}/${name}";
              hasDefault = builtins.pathExists "${sub}/default.nix";
          in
            (if hasDefault then [ "${sub}/default.nix" ] else [ ])
            ++ collectDefaultNix sub
        ) dirs
      );

  discoverOverlays =
    let
      oDir = "${root}/overlays";
      entries = builtins.readDir oDir;
      dirs = lib.filterAttrs (_name: type: type == "directory") entries;
      hasDefault = name: builtins.pathExists "${oDir}/${name}/default.nix";
      isDisabled = name: builtins.pathExists "${oDir}/${name}/disabled";
      active = lib.filterAttrs (name: _: hasDefault name && !isDisabled name) dirs;
    in
      map (name: import "${oDir}/${name}/default.nix" { }) (builtins.attrNames active);

  overlays = discoverOverlays;

  nixosModules = collectDefaultNix "${root}/modules/nixos";

  homeBase = "${root}/modules/home";

  # 按用途分组的 home 模块
  homeCore = collectDefaultNix "${homeBase}/core";
  homeService = collectDefaultNix "${homeBase}/service";
  homeDesktop = collectDefaultNix "${homeBase}/desktop";
  homeDev = collectDefaultNix "${homeBase}/dev";
  homeHerdr = collectDefaultNix "${homeBase}/herdr";

  # 所有系统共用的 home 模块
  homeModules = homeCore ++ homeService ++ homeHerdr;

  optionsModule = "${root}/modules/options.nix";

  # 所有系统共用的 HM 基础设施
  essentialHomeModules = [
    optionsModule
    inputs.lucy.homeManagerModules.default
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
    inputs.nvf.homeManagerModules.default
    inputs.rime-keytao.homeManagerModules.default
    inputs.vicinae.homeManagerModules.default
  ];

  desktopHomeModulesFull = desktopHomeModules ++ desktopExtraHomeModules;
in
{
  inherit
    root overlays nixosModules homeModules
    optionsModule essentialHomeModules
    desktopHomeModules desktopExtraHomeModules desktopHomeModulesFull;
}