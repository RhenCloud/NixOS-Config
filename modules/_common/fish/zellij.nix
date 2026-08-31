{
  pkgs,
  ...
}:

let
  zjstatus = pkgs.stdenvNoCC.mkDerivation {
    pname = "zjstatus";
    version = "0.23.0";
    src = pkgs.fetchurl {
      url = "https://github.com/dj95/zjstatus/releases/download/v0.23.0/zjstatus.wasm";
      hash = "sha256-4AaQEiNSQjnbYYAh5MxdF/gtxL+uVDKJW6QfA/E4Yf8=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/zjstatus.wasm
    '';
  };

  zellij-forgot = pkgs.stdenvNoCC.mkDerivation {
    pname = "zellij-forgot";
    version = "0.4.2";
    src = pkgs.fetchurl {
      url = "https://github.com/karimould/zellij-forgot/releases/download/0.4.2/zellij_forgot.wasm";
      hash = "sha256-MRlBRVGdvcEoaFtFb5cDdDePoZ/J2nQvvkoyG6zkSds=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/zellij_forgot.wasm
    '';
  };

  zjstatus-hints = pkgs.stdenvNoCC.mkDerivation {
    pname = "zjstatus-hints";
    version = "0.1.4";
    src = pkgs.fetchurl {
      url = "https://github.com/b0o/zjstatus-hints/releases/download/v0.1.4/zjstatus-hints.wasm";
      hash = "sha256-k2xV6QJcDtvUNCE4PvwVG9/ceOkk+Wa/6efGgr7IcZ0=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/zjstatus-hints.wasm
    '';
  };

  draculaTheme = ''
    themes {
        dracula {
            text_unselected {
                base 255 255 255
                background 0 0 0
                emphasis_0 255 184 108
                emphasis_1 139 233 253
                emphasis_2 80 250 123
                emphasis_3 255 121 198
            }
            text_selected {
                base 255 255 255
                background 40 42 54
                emphasis_0 255 184 108
                emphasis_1 139 233 253
                emphasis_2 80 250 123
                emphasis_3 255 121 198
            }
            ribbon_selected {
                base 0 0 0
                background 80 250 123
                emphasis_0 255 85 85
                emphasis_1 255 184 108
                emphasis_2 255 121 198
                emphasis_3 98 114 164
            }
            ribbon_unselected {
                base 0 0 0
                background 248 248 242
                emphasis_0 255 85 85
                emphasis_1 255 255 255
                emphasis_2 98 114 164
                emphasis_3 255 121 198
            }
            table_title {
                base 80 250 123
                background 0
                emphasis_0 255 184 108
                emphasis_1 139 233 253
                emphasis_2 80 250 123
                emphasis_3 255 121 198
            }
            table_cell_selected {
                base 255 255 255
                background 40 42 54
                emphasis_0 255 184 108
                emphasis_1 139 233 253
                emphasis_2 80 250 123
                emphasis_3 255 121 198
            }
            table_cell_unselected {
                base 255 255 255
                background 0 0 0
                emphasis_0 255 184 108
                emphasis_1 139 233 253
                emphasis_2 80 250 123
                emphasis_3 255 121 198
            }
            list_selected {
                base 255 255 255
                background 40 42 54
                emphasis_0 255 184 108
                emphasis_1 139 233 253
                emphasis_2 80 250 123
                emphasis_3 255 121 198
            }
            list_unselected {
                base 255 255 255
                background 0 0 0
                emphasis_0 255 184 108
                emphasis_1 139 233 253
                emphasis_2 80 250 123
                emphasis_3 255 121 198
            }
            frame_selected {
                base 80 250 123
                background 0
                emphasis_0 255 184 108
                emphasis_1 139 233 253
                emphasis_2 255 121 198
                emphasis_3 0
            }
            frame_highlight {
                base 255 184 108
                background 0
                emphasis_0 255 121 198
                emphasis_1 255 184 108
                emphasis_2 255 184 108
                emphasis_3 255 184 108
            }
            exit_code_success {
                base 80 250 123
                background 0
                emphasis_0 139 233 253
                emphasis_1 0 0 0
                emphasis_2 255 121 198
                emphasis_3 98 114 164
            }
            exit_code_error {
                base 255 85 85
                background 0
                emphasis_0 241 250 140
                emphasis_1 0
                emphasis_2 0
                emphasis_3 0
            }
            multiplayer_user_colors {
                player_1 255 121 198
                player_2 98 114 164
                player_3 0
                player_4 241 250 140
                player_5 139 233 253
                player_6 0
                player_7 255 85 85
                player_8 0
                player_9 0
                player_10 0
            }
        }
    }
  '';

  #   keybinds = ''
  #     keybinds clear-defaults=true {
  #         normal {
  #             // 直接绑定
  #             bind "Alt 1" { GoToTab 1; }
  #             bind "Alt 2" { GoToTab 2; }
  #             bind "Alt 3" { GoToTab 3; }
  #             bind "Alt 4" { GoToTab 4; }
  #             bind "Alt 5" { GoToTab 5; }
  #             bind "Alt 6" { GoToTab 6; }
  #             bind "Alt 7" { GoToTab 7; }
  #             bind "Alt 8" { GoToTab 8; }
  #             bind "Alt 9" { GoToTab 9; }

  #             bind "Alt [" { GoToPreviousTab; }
  #             bind "Alt ]" { GoToNextTab; }

  #             bind "Ctrl u" { HalfPageScrollUp; }
  #             bind "Ctrl d" { HalfPageScrollDown; }
  #         }

  #         // 窗格模式: Ctrl p
  #         pane {
  #             bind "Ctrl p" { SwitchToMode "Normal"; }
  #             // 焦点移动
  #             bind "h" "Left" { MoveFocus "Left"; }
  #             bind "j" "Down" { MoveFocus "Down"; }
  #             bind "k" "Up" { MoveFocus "Up"; }
  #             bind "l" "Right" { MoveFocus "Right"; }
  #             // 分屏
  #             bind "\\" { NewPane "Right"; SwitchToMode "Normal"; }
  #             bind "-" { NewPane "Down"; SwitchToMode "Normal"; }
  #             bind "d" { NewPane "Down"; SwitchToMode "Normal"; }
  #             bind "r" { NewPane "Right"; SwitchToMode "Normal"; }
  #             // 关闭
  #             bind "x" { CloseFocus; SwitchToMode "Normal"; }
  #             // 浮动 & 全屏
  #             bind "f" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
  #             bind "w" { ToggleFloatingPanes; SwitchToMode "Normal"; }
  #             bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }
  #         }

  #         // 标签页模式: Ctrl t
  #         tab {
  #             bind "Ctrl t" { SwitchToMode "Normal"; }
  #             bind "n" { NewTab; SwitchToMode "Normal"; }
  #             bind "x" { CloseTab; SwitchToMode "Normal"; }
  #             bind "1" { GoToTab 1; SwitchToMode "Normal"; }
  #             bind "2" { GoToTab 2; SwitchToMode "Normal"; }
  #             bind "3" { GoToTab 3; SwitchToMode "Normal"; }
  #             bind "4" { GoToTab 4; SwitchToMode "Normal"; }
  #             bind "5" { GoToTab 5; SwitchToMode "Normal"; }
  #             bind "6" { GoToTab 6; SwitchToMode "Normal"; }
  #             bind "7" { GoToTab 7; SwitchToMode "Normal"; }
  #             bind "8" { GoToTab 8; SwitchToMode "Normal"; }
  #             bind "9" { GoToTab 9; SwitchToMode "Normal"; }
  #             bind "[" { GoToPreviousTab; SwitchToMode "Normal"; }
  #             bind "]" { GoToNextTab; SwitchToMode "Normal"; }
  #             bind "r" { SwitchToMode "RenameTab"; }
  #         }

  #         // 调整大小模式: Ctrl n
  #         resize {
  #             bind "Ctrl n" { SwitchToMode "Normal"; }
  #             bind "h" "Left" { Resize "Increase Left"; }
  #             bind "j" "Down" { Resize "Increase Down"; }
  #             bind "k" "Up" { Resize "Increase Up"; }
  #             bind "l" "Right" { Resize "Increase Right"; }
  #             bind "H" { Resize "Decrease Left"; }
  #             bind "J" { Resize "Decrease Down"; }
  #             bind "K" { Resize "Decrease Up"; }
  #             bind "L" { Resize "Decrease Right"; }
  #         }

  #         // 会话模式: Ctrl o
  #         session {
  #             bind "Ctrl o" { SwitchToMode "Normal"; }
  #             bind "d" { Detach; }
  #             bind "w" {
  #                 LaunchOrFocusPlugin "session-manager" {
  #                     floating true
  #                 };
  #                 SwitchToMode "Normal"
  #             }
  #         }

  #         // 滚动模式: Ctrl s
  #         scroll {
  #             bind "Ctrl s" { SwitchToMode "Normal"; }
  #             bind "j" "Down" { ScrollDown; }
  #             bind "k" "Up" { ScrollUp; }
  #             bind "u" { HalfPageScrollUp; }
  #             bind "d" { HalfPageScrollDown; }
  #             bind "s" { SwitchToMode "Search"; }
  #         }

  #         // 搜索模式
  #         search {
  #             bind "Ctrl c" "Esc" { SwitchToMode "Normal"; }
  #             bind "n" { Search "down"; }
  #             bind "N" { Search "up"; }
  #         }

  #         // 重命名标签页模式
  #         renametab {
  #             bind "Ctrl c" "Esc" { SwitchToMode "Normal"; }
  #         }

  #         // 锁定模式
  #         locked {
  #             bind "Ctrl g" { SwitchToMode "Normal"; }
  #         }

  #         // 模式入口键 (除锁定外均可用)
  #         shared_except "locked" {
  #             bind "Ctrl p" { SwitchToMode "Pane"; }
  #             bind "Ctrl t" { SwitchToMode "Tab"; }
  #             bind "Ctrl n" { SwitchToMode "Resize"; }
  #             bind "Ctrl o" { SwitchToMode "Session"; }
  #             bind "Ctrl s" { SwitchToMode "Scroll"; }
  #             bind "Ctrl g" { SwitchToMode "Locked"; }

  #             // zellij-forgot 快捷键提示
  #             bind "Ctrl y" {
  #                 LaunchOrFocusPlugin "file:${zellij-forgot}/bin/zellij_forgot.wasm" {
  #                     floating true

  #                     "── 模式 ──" ""
  #                     "窗格模式" "Ctrl p → h/j/k/l 移动 / \\- 分屏 / x 关闭 / f 全屏 / w 浮动 / e 嵌入"
  #                     "标签模式" "Ctrl t → n 新建 / x 关闭 / 1-9 跳转 / [ ] 切换 / r 重命名"
  #                     "调整大小" "Ctrl n → h/j/k/l 调整"
  #                     "会话模式" "Ctrl o → d 分离 / w 管理器"
  #                     "滚动搜索" "Ctrl s → j/k 滚动 / u/d 半页 / s 搜索"

  #                     "── 直接 ──" ""
  #                     "切换标签" "Alt 1-9 / Alt [ ]"
  #                     "滚动" "Ctrl u / Ctrl d"
  #                     "锁定/解锁" "Ctrl g"

  #                     "── 插件 ──" ""
  #                     "快捷键提示" "Ctrl y"
  #                 }
  #             }
  #         }
  #     }
  #   '';

  layout = ''
    layout {
        default_tab_template {
            children
            pane size=1 borderless=true {
                plugin location="file:${zjstatus}/bin/zjstatus.wasm" {
                    border_enabled  "true"
                    border_char     "─"
                    border_format   "#[fg=#6272A4]{char}"
                    border_position "top"

                    format_left   " {mode}  #[fg=#8BE9FD,bold] {session}"
                    format_center "{tabs}"
                    format_right  "{pipe_zjstatus_hints} {command_hostname}"

                    pipe_zjstatus_hints_format "{output}"

                    format_hide_on_overlength "true"
                    format_precedence         "crl"

                    tab_normal    "#[fg=#6272A4] {index}: {name}{fullscreen_indicator}{sync_indicator}{floating_indicator} "
                    tab_active    "#[fg=#282A36,bg=#BD93F9,bold] {index}: {name}{fullscreen_indicator}{sync_indicator}{floating_indicator} "
                    tab_fullscreen_indicator " □"
                    tab_sync_indicator       " "
                    tab_floating_indicator   " 󰉈"
                    tab_separator "#[fg=#6272A4]│"

                    session "#[fg=#8BE9FD,bold] {name}"

                    command_hostname_command    "hostname"
                    command_hostname_format     "#[fg=#F8F8F2]󰒋 {stdout}"
                    command_hostname_interval   "0"
                    command_hostname_rendermode "static"

                    mode_normal        "#[fg=#50FA7B]NORMAL"
                    mode_locked        "#[fg=#6272A4]LOCKED "
                    mode_resize        "#[fg=#FF5555]RESIZE"
                    mode_pane          "#[fg=#8BE9FD]PANE"
                    mode_tab           "#[fg=#BD93F9]TAB"
                    mode_scroll        "#[fg=#F1FA8C]SCROLL"
                    mode_enter_search  "#[fg=#8BE9FD]ENT-SEARCH"
                    mode_search        "#[fg=#8BE9FD]SEARCHARCH"
                    mode_rename_tab    "#[fg=#BD93F9]RENAME-TAB"
                    mode_rename_pane   "#[fg=#8BE9FD]RENAME-PANE"
                    mode_session       "#[fg=#8BE9FD]SESSION"
                    mode_move          "#[fg=#BD93F9]MOVE"
                    mode_prompt        "#[fg=#8BE9FD]PROMPT"
                }
            }
        }

        tab name="musicfox" {
            pane command="musicfox"
        }

        tab name="nixos" {
            pane cwd="$HOME/nixos"
        }
    }
  '';

  keybinds = ''
    keybinds {
        normal {
            bind "Alt t" { NewTab; }
            bind "Alt q" { CloseTab; }
            bind "Alt 1" { GoToTab 1; }
            bind "Alt 2" { GoToTab 2; }
            bind "Alt 3" { GoToTab 3; }
            bind "Alt 4" { GoToTab 4; }
            bind "Alt 5" { GoToTab 5; }
            bind "Alt 6" { GoToTab 6; }
            bind "Alt 7" { GoToTab 7; }
            bind "Alt 8" { GoToTab 8; }
            bind "Alt 9" { GoToTab 9; }
            bind "Ctrl m" { NewPane "Right"; }
            bind "Ctrl n" { NewPane "Down"; }
            bind "Alt w" { CloseFocus; }
        }
    }
  '';

  pluginsAndLoad = ''
    plugins {
        zjstatus-hints location="file:${zjstatus-hints}/bin/zjstatus-hints.wasm" {
        }
    }

    load_plugins {
        zjstatus-hints
    }
  '';

  fishTabNameScript = ''
    function __zellij_current_tab_field --argument-names field
        command zellij action current-tab-info 2>/dev/null \
            | string match -r "^$field: .*" \
            | string replace -r "^$field: " ""
    end

    function __zellij_auto_tab_state_file --argument-names tab_id
        set -l state_dir "$(set -q XDG_RUNTIME_DIR; and printf '%s' $XDG_RUNTIME_DIR; or printf /tmp)/zellij-auto-tab-names"
        mkdir -p "$state_dir" 2>/dev/null; or return 1

        set -l session_name (string escape --style=url -- "$ZELLIJ_SESSION_NAME")
        printf "%s/%s-%s" "$state_dir" "$session_name" "$tab_id"
    end

    function __zellij_rename_tab_on_pwd --on-variable PWD
        set -q ZELLIJ; or return

        set -l current_name (__zellij_current_tab_field name)
        set -l tab_id (__zellij_current_tab_field id)
        test -n "$current_name"; and test -n "$tab_id"; or return

        set -l state_file (__zellij_auto_tab_state_file "$tab_id")
        test -n "$state_file"; or return

        set -l last_auto_name
        test -f "$state_file"; and set last_auto_name (string collect <"$state_file")

        # 已手动命名的标签页不再跟随目录名。
        if test -n "$last_auto_name"; and test "$current_name" != "$last_auto_name"
            return
        end

        set -l tab_name (basename "$PWD")
        test "$PWD" = "$HOME"; and set tab_name "~"
        test -z "$tab_name"; and set tab_name "/"

        command zellij action rename-tab "$tab_name" >/dev/null 2>&1; or return
        printf "%s" "$tab_name" >"$state_file"
    end

    function ssh --wraps="ssh"
        if set -q ZELLIJ
            set -l host ""
            for arg in $argv
                if not string match -q -- '-*' "$arg"
                    set host $arg
                    break
                end
            end
            if test -n "$host"
                set -l tab_id (__zellij_current_tab_field id)
                if test -n "$tab_id"
                    set -l state_file (__zellij_auto_tab_state_file "$tab_id")
                    if test -n "$state_file"
                        printf "ssh:%s" "$host" >"$state_file"
                    end
                    command zellij action rename-tab "ssh:$host" >/dev/null 2>&1
                end
            end
        end
        command ssh $argv
    end

    function opencode --wraps="opencode"
        if set -q ZELLIJ
            set -l proj (basename "$PWD")
            test "$PWD" = "$HOME"; and set proj "~"

            set -l tab_id (__zellij_current_tab_field id)
            if test -n "$tab_id"
                set -l state_file (__zellij_auto_tab_state_file "$tab_id")
                if test -n "$state_file"
                    printf "oc:%s" "$proj" >"$state_file"
                end
                command zellij action rename-tab "󰚩 $proj" >/dev/null 2>&1
            end

            command opencode $argv
            set -l oc_exit $status

            if set -q ZELLIJ; and test -n "$tab_id"
                if test $oc_exit -eq 0
                    command zellij action rename-tab " $proj" >/dev/null 2>&1
                else
                    command zellij action rename-tab " $proj" >/dev/null 2>&1
                end
            end

            return $oc_exit
        else
            command opencode $argv
        end
    end

    __zellij_rename_tab_on_pwd
  '';
in
{
  programs.zellij = {
    enable = true;
    enableFishIntegration = false;

    settings = {
      default_shell = "/run/current-system/sw/bin/fish";
      default_layout = "default";
      session_serialization = false;
      pane_frames = false;
      session_name = "main-session";
      show_release_notes = false;
      show_startup_tips = false;
      theme = "dracula";
    };

    extraConfig = draculaTheme + "\n\n" + keybinds + "\n\n" + pluginsAndLoad;

    layouts.default = layout;
  };

  xdg.configFile."fish/conf.d/90-zellij-tab-name.fish".text = fishTabNameScript;

  home.packages = [
    zjstatus
    zellij-forgot
    zjstatus-hints
  ];
}
