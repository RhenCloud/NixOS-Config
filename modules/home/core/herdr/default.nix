{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  herdrPkg = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  plugins = lib.attrValues config.rhencloud.herdrPlugins;
in

{
  imports = [
    ./herdr
    ./plugins
  ];

  options.rhencloud.herdrPlugins = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        id = lib.mkOption {
          type = lib.types.str;
          description = "插件 ID（必须匹配 herdr-plugin.toml 中的 id）";
        };
        package = lib.mkOption {
          type = lib.types.package;
          description = "提供 share/<id>/herdr-plugin.toml 和二进制文件的包";
        };
      };
    });
    default = { };
    description = "各插件模块自行注册到此处";
  };

  config = {
    home.packages = [ herdrPkg ] ++ (map (p: p.package) plugins);

    xdg.configFile = lib.listToAttrs (
      map (plugin: {
        name = "herdr/plugins/${plugin.id}/herdr-plugin.toml";
        value.source = "${plugin.package}/share/${plugin.id}/herdr-plugin.toml";
      }) plugins
    );
  };
}
