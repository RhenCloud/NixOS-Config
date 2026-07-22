{
  ...
}:

{
  xdg.configFile."fish/conf.d/93-herdr-layout.fish".text = ''
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
        and herdr status server >/dev/null 2>&1
        __herdr_ensure_layout
    end
  '';
}
