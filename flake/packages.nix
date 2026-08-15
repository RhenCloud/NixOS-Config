{ inputs, lib, ... }:
let
  # 自动发现 packages/<name>/default.nix
  discoverPackages =
    pkgs:
    let
      pDir = toString ../packages;
      entries = builtins.readDir pDir;
      dirs = lib.filterAttrs (_name: type: type == "directory") entries;
      hasDefault = name: builtins.pathExists "${pDir}/${name}/default.nix";
      isDisabled = name: builtins.pathExists "${pDir}/${name}/disabled";
      pkgDirs = lib.filterAttrs (name: _: hasDefault name && !isDisabled name) dirs;
    in
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = pkgs.callPackage "${pDir}/${name}/default.nix" { };
      }) (builtins.attrNames pkgDirs)
    );
in
{
  perSystem = { pkgs, ... }: {
    packages = (discoverPackages pkgs) // {
      rime-keytao = inputs.rime-keytao.packages.${pkgs.stdenv.hostPlatform.system}.default;
      # 固定 deploy-rs 版本（跟随 flake.lock），供 deploy.yml 使用
      deploy-rs = inputs.deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.deploy-rs;
    };
  };
}
