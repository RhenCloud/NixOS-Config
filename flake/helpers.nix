{ lib, inputs }:
let
  root = toString inputs.self;

  collectDefaultNix = dir:
    let
      entries = builtins.readDir dir;
      dirs = lib.filterAttrs (name: type: type == "directory") entries;
    in
      lib.flatten (
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
      dirs = lib.filterAttrs (name: type: type == "directory") entries;
      hasDefault = name: builtins.pathExists "${oDir}/${name}/default.nix";
      isDisabled = name: builtins.pathExists "${oDir}/${name}/disabled";
      active = lib.filterAttrs (name: _: hasDefault name && !isDisabled name) dirs;
    in
      map (name: import "${oDir}/${name}/default.nix" { }) (builtins.attrNames active);

  overlays = discoverOverlays;

  nixosModules = collectDefaultNix "${root}/modules/nixos";
  homeModules = collectDefaultNix "${root}/modules/home";

  optionsModule = "${root}/modules/options.nix";

  pkgsFor = import inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };

  commonHomeModules = [
    inputs.mangowm.hmModules.mango
    inputs.niri.homeModules.niri
    inputs.lucy.homeManagerModules.default
    inputs.noctalia-v4.homeModules.default
    inputs.piri.homeManagerModules.default
    inputs.nvf.homeManagerModules.default
    inputs.rime-keytao.homeManagerModules.default
    inputs.vicinae.homeManagerModules.default
    inputs.nix-index-database.homeModules.nix-index
    optionsModule
    { nixpkgs.overlays = overlays; }
    ({ config, ... }: {
      nixpkgs.config.allowUnfree = config.my.allowUnfree;
      nixpkgs.config.permittedInsecurePackages = config.my.permittedInsecurePackages;
    })
  ];
in
{
  inherit
    root overlays nixosModules homeModules
    pkgsFor optionsModule commonHomeModules;
}
