set -g fish_greeting ''
# tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time='24-hour format' --rainbow_prompt_separators=Angled --powerline_prompt_heads=Sharp --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character' --prompt_connection=Dotted --powerline_right_prompt_frame=No --prompt_connection_andor_frame_color=Light --prompt_spacing=Sparse --icons='Many icons' --transient=Yes

fish_config theme choose Dracula

export ALIYUNPAN_CONFIG_DIR=$HOME/.config/aliyunpan
export ALIYUNPAN_DOWNLOAD_DIR=$HOME/Downloads/aliyunpan

export _ZO_EXCLUDE_DIRS="/tmp:/var:/proc:/sys"
export _ZO_EXCLUDE_DIRS="/tmp:/var:/node_modules:/.git:/__pycache__"

set --universal pure_enable_nixdevshell true
set --universal pure_symbol_virtualenv_prefix 🐍
set --universal pure_show_exit_status true
set --universal pure_show_subsecond_command_duration true
set --universal fish_transient_prompt true
set -g async_prompt_functions _pure_prompt_git

# Auto-start zellij for interactive terminals, except in VS Code integrated terminal.
if status is-interactive
    and not set -q ZELLIJ
    and not set -q VSCODE_INJECTION
    and test "$TERM_PROGRAM" != vscode
    and command -sq zellij
    set -l zellij_session main-session

    # Self-heal stale resurrected layouts that reference a garbage-collected fish binary.
    set -l should_reset_session 0
    for layout in ~/.cache/zellij/*/session_info/$zellij_session/session-layout.kdl
        if test -f "$layout"
            set -l cached_fish_paths (sed -n 's/.*command="\([^"]*\/bin\/fish\)".*/\1/p' "$layout")
            for fish_path in $cached_fish_paths
                if test ! -x "$fish_path"
                    set should_reset_session 1
                    break
                end
            end
        end
        if test $should_reset_session -eq 1
            break
        end
    end

    if test $should_reset_session -eq 1
        zellij delete-session $zellij_session >/dev/null 2>&1
    end

    zellij attach -c $zellij_session
end

function spf
    set -l spf_last_dir_path "$HOME/.local/share/superfile/lastdir"

    command spf $argv

    if test -f "$spf_last_dir_path"
        set -l spf_last_dir (string trim (cat "$spf_last_dir_path"))
        if test -n "$spf_last_dir"; and test -d "$spf_last_dir"
            cd "$spf_last_dir"
        end
        rm -f "$spf_last_dir_path"
    end
end
