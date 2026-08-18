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

# Tide prompt structural config (mirror of "tide configure" output used on all hosts)
set --universal tide_left_prompt_frame_enabled false
set --universal tide_left_prompt_items os pwd git newline character
set --universal tide_left_prompt_prefix ""
set --universal tide_left_prompt_separator_diff_color \ue0b0
set --universal tide_left_prompt_separator_same_color \ue0b1
set --universal tide_left_prompt_suffix \ue0b0
set --universal tide_right_prompt_frame_enabled false
set --universal tide_right_prompt_items status cmd_duration context jobs direnv bun node python rustc java php pulumi ruby go gcloud kubectl distrobox toolbox terraform aws nix_shell crystal elixir zig time
set --universal tide_right_prompt_prefix \ue0b2
set --universal tide_right_prompt_separator_diff_color \ue0b2
set --universal tide_right_prompt_separator_same_color \ue0b3
set --universal tide_right_prompt_suffix ""
set --universal tide_prompt_transient_enabled true
set --universal tide_prompt_add_newline_before true
set --universal tide_prompt_min_cols 34
set --universal tide_prompt_pad_items true
set --universal tide_prompt_icon_connection \u00b7
set --universal tide_character_icon \u276f
set --universal tide_character_vi_icon_default \u276e
set --universal tide_character_vi_icon_replace \u25b6
set --universal tide_character_vi_icon_visual V
set --universal tide_status_icon \u2714
set --universal tide_status_icon_failure \u2718
set --universal tide_cmd_duration_decimals 0
set --universal tide_cmd_duration_icon \uf252
set --universal tide_cmd_duration_threshold 3000
set --universal tide_jobs_icon \uf013
set --universal tide_jobs_number_threshold 1000
set --universal tide_context_always_display false
set --universal tide_context_hostname_parts 1
set --universal tide_git_icon \uf1d3
set --universal tide_git_truncation_length 24
set --universal tide_git_truncation_strategy ""
set --universal tide_pwd_icon \uf07c
set --universal tide_pwd_icon_home \uf015
set --universal tide_pwd_icon_unwritable \uf023
set --universal tide_pwd_markers .bzr .citc .git .hg .node-version .python-version .ruby-version .shorten_folder_marker .svn .terraform bun.lockb Cargo.toml composer.json CVS go.mod package.json build.zig
set --universal tide_aws_icon \uf270
set --universal tide_bun_icon \U000f0cd3
set --universal tide_crystal_icon \ue62f
set --universal tide_direnv_icon \u25bc
set --universal tide_distrobox_icon \U000f01a7
set --universal tide_docker_icon \uf308
set --universal tide_docker_default_contexts default colima
set --universal tide_elixir_icon \ue62d
set --universal tide_gcloud_icon \U000f02ad
set --universal tide_go_icon \ue627
set --universal tide_java_icon \ue256
set --universal tide_kubectl_icon \U000f10fe
set --universal tide_nix_shell_icon \uf313
set --universal tide_node_icon \ue24f
set --universal tide_os_icon \uf313
set --universal tide_php_icon \ue608
set --universal tide_private_mode_icon \U000f05f9
set --universal tide_pulumi_icon \uf1b2
set --universal tide_python_icon \U000f0320
set --universal tide_ruby_icon \ue23e
set --universal tide_rustc_icon \ue7a8
set --universal tide_shlvl_icon \uf120
set --universal tide_shlvl_threshold 1
set --universal tide_terraform_icon \U000f1062
set --universal tide_toolbox_icon \ue24f
set --universal tide_zig_icon \ue6a9
set --universal tide_vi_mode_icon_default D
set --universal tide_vi_mode_icon_insert I
set --universal tide_vi_mode_icon_replace R
set --universal tide_vi_mode_icon_visual V
set --universal tide_time_format %T

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
