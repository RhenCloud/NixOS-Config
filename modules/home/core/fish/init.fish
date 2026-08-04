set -g fish_greeting ''

fish_config theme choose Dracula

# Tide prompt in Dracula palette
set --universal tide_character_color 50FA7B
set --universal tide_character_color_failure FF5555
set --universal tide_cmd_duration_bg_color 44475A
set --universal tide_context_color_default F8F8F2
set --universal tide_context_color_root FF5555
set --universal tide_context_color_ssh FF79C6
set --universal tide_git_bg_color 44475A
set --universal tide_git_bg_color_unstable 44475A
set --universal tide_git_bg_color_urgent 44475A
set --universal tide_git_color_branch BD93F9
set --universal tide_git_color_conflicted FF5555
set --universal tide_git_color_dirty F1FA8C
set --universal tide_git_color_operation 50FA7B
set --universal tide_git_color_staged 50FA7B
set --universal tide_git_color_stash 6272A4
set --universal tide_git_color_untracked F1FA8C
set --universal tide_git_color_upstream 8BE9FD
set --universal tide_jobs_color FF79C6
set --universal tide_private_mode_color F8F8F2
set --universal tide_status_color 50FA7B
set --universal tide_status_color_failure FF5555
set --universal tide_time_color 6272A4
set --universal tide_prompt_color_frame_and_connection 6272A4
set --universal tide_prompt_color_separator_same_color 6272A4
set --universal tide_pwd_bg_color 44475A
set --universal tide_pwd_color_anchors 8BE9FD
set --universal tide_pwd_color_dirs F8F8F2
set --universal tide_pwd_color_truncated_dirs 6272A4

# lorri hook fish | source

export ALIYUNPAN_CONFIG_DIR=$HOME/.config/aliyunpan
export ALIYUNPAN_DOWNLOAD_DIR=$HOME/Downloads/aliyunpan

export _ZO_EXCLUDE_DIRS="/tmp:/var:/proc:/sys"
export _ZO_EXCLUDE_DIRS="/tmp:/var:/node_modules:/.git:/__pycache__"

set --universal fish_transient_prompt true

# # Auto-start zellij for interactive terminals, except in VS Code integrated terminal.
# if status is-interactive
#     and not set -q ZELLIJ
#     and not set -q VSCODE_INJECTION
#     and test "$TERM_PROGRAM" != vscode
#     and command -sq zellij
#     set -l zellij_session main-session
#
#     # Self-heal stale resurrected layouts that reference a garbage-collected fish binary.
#     set -l should_reset_session 0
#     for layout in ~/.cache/zellij/*/session_info/$zellij_session/session-layout.kdl
#         if test -f "$layout"
#             set -l cached_fish_paths (sed -n 's/.*command="\([^"]*\/bin\/fish\)".*/\1/p' "$layout")
#             for fish_path in $cached_fish_paths
#                 if test ! -x "$fish_path"
#                     set should_reset_session 1
#                     break
#                 end
#             end
#         end
#         if test $should_reset_session -eq 1
#             break
#         end
#     end
#
#     if test $should_reset_session -eq 1
#         zellij delete-session $zellij_session >/dev/null 2>&1
#     end
#
#     zellij attach -c $zellij_session
# end

# Auto-start herdr for interactive terminals, except in VS Code or Zed integrated terminal.
if status is-interactive
    and not set -q HERDR_ENV
    and not set -q VSCODE_INJECTION
    and test "$TERM_PROGRAM" != vscode
    and test "$TERM_PROGRAM" != zed
    and command -sq herdr
    herdr
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
