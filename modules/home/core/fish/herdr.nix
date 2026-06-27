{
  pkgs,
  inputs,
  ...
}:

let
  herdrPkg = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  renamePkg = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-tab-rename;

  herdrLayoutScript = ''
    function __herdr_ensure_layout
      set -l marker "$HOME/.local/share/herdr/layout-setup-done"
      if test -f "$marker"
        return 0
      end

      herdr workspace close 1 2>/dev/null

      herdr workspace create --cwd "$HOME/nixos" --label "nixos" --no-focus 2>/dev/null

      set -l result (herdr workspace create --cwd "$HOME" --label "musicfox" --no-focus 2>/dev/null)
      set -l ws_id (echo "$result" | string match -gr '"workspace":\s*"(\d+)"')
      if test -n "$ws_id"
        herdr pane run "$ws_id-1" "musicfox" >/dev/null 2>&1
      end

      mkdir -p "$HOME/.local/share/herdr"
      touch "$marker"
    end

    if status is-interactive
        and not set -q HERDR_ENV
        and not set -q VSCODE_INJECTION
        and test "$TERM_PROGRAM" != vscode
        and command -sq herdr

        if not herdr status server >/dev/null 2>&1
            herdr server </dev/null >/dev/null 2>&1 & disown
            for i in (seq 1 30)
                if herdr status server >/dev/null 2>&1
                    break
                end
                sleep 0.2
            end
        end

        if herdr status server >/dev/null 2>&1
            # 注册 herdr-tab-rename 插件
            set -l plugin_dir "$HOME/.config/herdr/plugins/rhencloud.tab-rename"
            if test -d "$plugin_dir"
                and not herdr plugin list 2>/dev/null | string match -q "rhencloud.tab-rename"
                herdr plugin link "$plugin_dir" >/dev/null 2>&1
            end

            __herdr_ensure_layout
        end
    end
  '';

  herdrTabRenameScript = ''
    function __herdr_rename_tab_on_pwd --on-variable PWD
      set -q HERDR_ENV; or return
      herdr-tab-rename on-pwd
    end

    function ssh --wraps="ssh"
      if set -q HERDR_ENV
        set -l host ""
        for arg in $argv
          if not string match -q -- '-*' "$arg"
            set host $arg
            break
          end
        end
        if test -n "$host"
          herdr-tab-rename on-ssh --host "$host"
        end
      end
      command ssh $argv
    end

    function opencode --wraps="opencode"
      if set -q HERDR_ENV
        set -l proj (basename "$PWD")
        test "$PWD" = "$HOME"; and set proj "~"
        herdr-tab-rename opencode-before --project "$proj"
        command opencode $argv
        set -l oc_exit $status
        herdr-tab-rename opencode-after --project "$proj" --exit-code $oc_exit
        return $oc_exit
      else
        command opencode $argv
      end
    end

    __herdr_rename_tab_on_pwd
  '';
in

{
  home.packages = [ herdrPkg renamePkg ];

  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [theme]
    name = "dracula"

    [keys]
    previous_tab = "alt+h"
    next_tab = "alt+l"
    previous_workspace = "alt+k"
    next_workspace = "alt+j"
    previous_agent = "alt+i"
    next_agent = "alt+o"

    [ui]
    show_agent_labels_on_pane_borders = true

    [terminal]
    default_shell = "/run/current-system/sw/bin/fish"
    shell_mode = "auto"

    [experimental]
    switch_ascii_input_source_in_prefix = true
  '';

  xdg.configFile."herdr/plugins/rhencloud.tab-rename/herdr-plugin.toml".source =
    "${renamePkg}/share/herdr-tab-rename/herdr-plugin.toml";

  xdg.configFile."fish/conf.d/91-herdr-layout.fish".text = herdrLayoutScript;

  xdg.configFile."fish/conf.d/93-herdr-tab-rename.fish".text = herdrTabRenameScript;
}
