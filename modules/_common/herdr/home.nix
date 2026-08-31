{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./herdr/mod.nix
    ./plugins/mod.nix
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

  options.rhencloud.herdr.enable = lib.mkEnableOption "Herdr terminal multiplexer";

  config = lib.mkIf config.rhencloud.herdr.enable {
    home.packages = [
      inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]
    ++ (map (p: p.package) (lib.attrValues config.rhencloud.herdrPlugins));

    xdg.configFile = lib.listToAttrs (
      map (plugin: {
        name = "herdr/plugins/${plugin.id}/herdr-plugin.toml";
        value.source = "${plugin.package}/share/${plugin.id}/herdr-plugin.toml";
      }) (lib.attrValues config.rhencloud.herdrPlugins)
    );
  };
}
