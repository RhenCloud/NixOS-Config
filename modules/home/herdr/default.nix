{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.herdr;
  herdrPkg = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  plugins = lib.attrValues config.rhencloud.herdrPlugins;
in
{
  imports = [
    ./herdr
    ./plugins
  ];

  options.rhencloud.herdrPlugins = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          id = lib.mkOption {
            type = lib.types.str;
            description = "Plugin ID (must match herdr-plugin.toml id)";
          };
          package = lib.mkOption {
            type = lib.types.package;
            description = "Package providing share/<id>/herdr-plugin.toml and binaries";
          };
        };
      }
    );
    default = { };
    description = "Plugins register themselves here";
  };

  options.rhencloud.herdr.enable = mkEnableOption "Herdr terminal multiplexer";

  config = mkIf cfg.enable {
    home.packages = [ herdrPkg ] ++ (map (p: p.package) plugins);

    xdg.configFile = lib.listToAttrs (
      map (plugin: {
        name = "herdr/plugins/${plugin.id}/herdr-plugin.toml";
        value.source = "${plugin.package}/share/${plugin.id}/herdr-plugin.toml";
      }) plugins
    );
  };
}
