{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # v5 beta 包（原生重写），二进制为 `noctalia`，由各合成器 autostart 启动。
  noctaliaV5 = inputs.noctalia-latest.packages.${system}.default;

  # 显式包装器，便于手动无歧义地启动。
  noctaliaV5Launcher = pkgs.writeShellScriptBin "noctalia-v5" ''
    exec ${noctaliaV5}/bin/noctalia "$@"
  '';
in
with lib;
let
  cfg = config.rhencloud.noctalia;
in
{
  options.rhencloud.noctalia.enable = mkEnableOption "Noctalia shell";

  config = mkIf cfg.enable {
    home.packages = [
      noctaliaV5
      noctaliaV5Launcher
      pkgs.evtest
    ];

    # 取色引擎：从壁纸生成调色板，并按内建/社区/用户模板分发到各应用。
    # 该层（~/.config/noctalia/*.toml）只读；GUI 改动写在 state 层。
    xdg.configFile."noctalia/config.toml".text = ''
      [theme]
      mode = "dark"
      source = "wallpaper"
      wallpaper_scheme = "m3-content"

      [theme.templates]
      enable_builtin_templates = true
      enable_community_templates = true
      builtin_ids = [ "niri", "kitty", "foot", "gtk3", "gtk4", "helix" ]
      # community_ids 取 catalog 的「模板组 ID」（即组名），组内所有 template 会自动全部应用：
      # 例如 yazi 组含 yazi + yazi-syntax；zen-browser 组含 zen_browser_chrome + zen_browser_content；
      # vscode 组含 vscode_code。填写单个 template ID（如 yazi-syntax、vscode_code）无法匹配、会被跳过。
      community_ids = [
        "bat",
        "yazi",
        "opencode",
        "vscode",
        "prismlauncher",
        "zen-browser",
        "glow",
        "inkscape",
        "zed",
        "fastfetch",
        "obs",
        "heroiclauncher",
        "lazygit",
        "blender",
      ]

      # 自写用户模板：社区 fzf 模板使用 `set -Ux` 会令 universal 变量无界增长，
      # 这里改为 `set -gx`，输出可在 fish 启动时安全重复 source。
      [theme.templates.user.fzf]
      input_path = "$XDG_CONFIG_HOME/noctalia/templates/fzf.fish"
      output_path = "$XDG_CONFIG_HOME/fzf/themes/noctalia.fish"

      # go-musicfox 自定义主题（社区无对应模板）；config.toml 的 activeTheme 指向 noctalia。
      [theme.templates.user.musicfox]
      input_path = "$XDG_CONFIG_HOME/noctalia/templates/musicfox.tmpl"
      output_path = "$XDG_CONFIG_HOME/go-musicfox/themes/noctalia.toml"

      # Vesktop：原版 Material Discord 主题，仅替换颜色，不改动任何布局样式。
      # 社区模板对应的是 Midnight 主题，结构与 Discord 原版差异较大，故改用自写模板。
      [theme.templates.user.vesktop]
      input_path = "$XDG_CONFIG_HOME/noctalia/templates/vesktop.css"
      output_path = "$XDG_CONFIG_HOME/vesktop/themes/noctalia.theme.css"

      # Fcitx5：以旧 dracula 主题为蓝本，仅把颜色换成 noctalia 取色结果，
      # 圆角/边距/SVG 等样式保持不变。三个文件分别渲染，写入同一主题目录。
      [theme.templates.user.fcitx5-conf]
      input_path = "$XDG_CONFIG_HOME/noctalia/templates/fcitx5/theme.conf"
      output_path = "$XDG_DATA_HOME/fcitx5/themes/noctalia/theme.conf"
      post_hook = "busctl --user call org.fcitx.Fcitx5 /controller org.fcitx.Fcitx.Controller1 ReloadAddonConfig s classicui"

      [theme.templates.user.fcitx5-panel]
      input_path = "$XDG_CONFIG_HOME/noctalia/templates/fcitx5/panel.svg"
      output_path = "$XDG_DATA_HOME/fcitx5/themes/noctalia/panel.svg"

      [theme.templates.user.fcitx5-highlight]
      input_path = "$XDG_CONFIG_HOME/noctalia/templates/fcitx5/highlight.svg"
      output_path = "$XDG_DATA_HOME/fcitx5/themes/noctalia/highlight.svg"

      # herdr：社区模板输出了 0.8.0 不认识的 sidebar_bg / active_row_bg / selection_bg，
      # 导致 config check 报 unknown key。此处只输出受支持的键。
      [theme.templates.user.herdr]
      input_path = "$XDG_CONFIG_HOME/noctalia/templates/herdr-colors.toml"
      output_path = "$XDG_CONFIG_HOME/herdr/noctalia-colors.toml"
      post_hook = "bash '$XDG_CONFIG_HOME/noctalia/templates/herdr-apply.sh'"
    '';

    # 自写模板源文件（noctalia 负责渲染其中的 {{colors.*}} 占位符）。
    xdg.configFile = {
      "noctalia/templates/fzf.fish".source = ./templates/fzf.fish;
      "noctalia/templates/musicfox.tmpl".source = ./templates/musicfox.tmpl;
      "noctalia/templates/vesktop.css".source = ./templates/vesktop.css;
      "noctalia/templates/fcitx5/theme.conf".source = ./templates/fcitx5/theme.conf;
      "noctalia/templates/fcitx5/panel.svg".source = ./templates/fcitx5/panel.svg;
      "noctalia/templates/fcitx5/highlight.svg".source = ./templates/fcitx5/highlight.svg;
      "noctalia/templates/herdr-colors.toml".source = ./templates/herdr-colors.toml;
      "noctalia/templates/herdr-apply.sh".source = ./templates/herdr-apply.sh;
    };

    # 首次登录或切换后，noctalia 尚未生成模板文件前先放置占位文件。
    # 仅针对「无条件 include/source」的接入（缺文件会导致整份配置解析失败）；
    # 按名称选取主题的应用（helix/zed/glow/musicfox 等）不预置，缺失时优雅回退。
    home.activation.noctaliaTemplatePlaceholders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      for f in \
        "$HOME/.config/niri/noctalia.kdl" \
        "$HOME/.config/kitty/themes/noctalia.conf" \
        "$HOME/.config/foot/themes/noctalia" \
        "$HOME/.config/gtk-3.0/noctalia.css" \
        "$HOME/.config/gtk-4.0/noctalia.css" \
        "$HOME/.config/fzf/themes/noctalia.fish"
      do
        if [ ! -e "$f" ]; then
          run mkdir -p "$(dirname "$f")"
          run touch "$f"
        fi
      done
    '';
  };
}
