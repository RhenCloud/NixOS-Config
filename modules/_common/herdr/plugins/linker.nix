{
  config,
  lib,
  ...
}:

let
  plugins = lib.attrValues config.rhencloud.herdrPlugins;
in

{
  xdg.configFile."fish/conf.d/92-herdr-plugins.fish".text = ''
    if status is-interactive
        and command -sq herdr
        and herdr status server >/dev/null 2>&1
        ${lib.concatStringsSep "\n" (
          map (plugin: ''
            set -l plugin_dir "$HOME/.config/herdr/plugins/${plugin.id}"
            if test -d "$plugin_dir"
                and not herdr plugin list 2>/dev/null | string match -q "${plugin.id}"
                herdr plugin link "$plugin_dir" >/dev/null 2>&1
            end
          '') plugins
        )}
    end
  '';
}
