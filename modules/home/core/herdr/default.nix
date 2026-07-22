{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  herdrPkg = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  cfg = config.rhencloud.herdrPlugins;
in

{
  imports = [
    ./herdr
    ./plugins
  ];

  options.rhencloud.herdrPlugins = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
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
      }
    );
    default = [
      {
        id = "rhencloud.tab-rename";
        package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-tab-rename;
      }
      {
        id = "herdr-spreader";
        package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-spreader;
      }
      {
        id = "rjyo.window-title-sync";
        package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-window-title-sync;
      }
      {
        id = "cloudmanic.herdr-plus";
        package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-plus;
      }
    ];
    description = "安装并注册的 herdr 插件列表";
  };

  config = {
    home.packages = [ herdrPkg ] ++ (map (p: p.package) cfg);

    xdg.configFile = lib.listToAttrs (
      map (plugin: {
        name = "herdr/plugins/${plugin.id}/herdr-plugin.toml";
        value.source = "${plugin.package}/share/${plugin.id}/herdr-plugin.toml";
      }) cfg
    );
  };
}
