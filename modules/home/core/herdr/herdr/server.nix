_:

{
  xdg.configFile."fish/conf.d/91-herdr-server.fish".text = ''
    if status is-interactive
        and command -sq herdr
        and not set -q HERDR_SOCKET
        if not herdr status server >/dev/null 2>&1
            herdr server </dev/null >/dev/null 2>&1 & disown
            for _ in (seq 1 50)
                if herdr status server >/dev/null 2>&1
                    break
                end
                sleep 0.1
            end
        end
    end
  '';
}
