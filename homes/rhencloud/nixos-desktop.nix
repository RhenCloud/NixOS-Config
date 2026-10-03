{
  config,
  lib,
  inputs,
  ...
}:
{
  # 此配置生成 homeConfigurations."rhencloud@nixos-desktop"
  # 继承 homes/rhencloud/default.nix 的基础配置
  rhen.isDesktop = true;

  rhen = {
    roles.dev.enable = true;

    fcitx5 = {
      enable = true;
      keytaoUserDict = ''
        李佳润	ljr
        泠云	lgyw
        联通性	ltx
        气笑了	qxl
        气笑	qx
      '';
    };

    # core
    browser.enable = true;
    git.enable = true;
    "hm-packages".enable = true;
    "hm-xdg".enable = true;
    "hm-wallpapers".enable = true;
    fish.enable = true;
    ghostty.enable = false;
    yazi.enable = true;
    fastfetch.enable = true;
    herdr.enable = true;
    # TTT 快捷键为 dict 覆盖格式（{ 命令id = 按键 }），只覆盖列出的命令，
    # 其余保持内置默认；ctrl+k 系均未占用，sidebar.changes 让出 ctrl+k c 给取色器
    ttt.keybindings = {
      "markdown.preview" = "ctrl+k v";
      "json.preview" = "ctrl+k h";
      "todos.scan" = "ctrl+k w";
      "colorPicker.open" = "ctrl+k c";
      "sidebar.changes" = "ctrl+k g";
    };
    ttt.plugins = {
      markdown-preview = {
        source = "${inputs.ttt-plugins}/markdown-preview";
        permissions = {
          "panel.editor" = true;
          commands = true;
          "editor.read" = true;
        };
      };
      json-viewer = {
        source = "${inputs.ttt-plugins}/json-viewer";
        permissions = {
          "panel.editor" = true;
          commands = true;
          "editor.read" = true;
        };
      };
      git-history = {
        source = "${inputs.ttt-plugins}/git-history";
        permissions = {
          "panel.sidebar" = true;
          commands = true;
          "system.exec" = [ "git" ];
          "editor.read" = true;
          "events.editor" = true;
        };
      };
      todo-scanner = {
        source = "${inputs.ttt-plugins}/todo-scanner";
        permissions = {
          "panel.bottom" = true;
          commands = true;
          "system.exec" = [ "rg" ];
        };
      };
      color-picker = {
        source = "${inputs.ttt-plugins}/color-picker";
        permissions = {
          "panel.drawer" = true;
          commands = true;
          keybindings = true;
          "editor.read" = true;
          "editor.write" = true;
        };
      };
      lsp-go = {
        source = "${inputs.ttt-plugins}/lsp-go";
        permissions = {
          settings = true;
          settings_keys = [ "lsp.*" ];
        };
      };
      lsp-typescript = {
        source = "${inputs.ttt-plugins}/lsp-typescript";
        permissions = {
          settings = true;
          settings_keys = [ "lsp.*" ];
        };
      };
      lsp-c = {
        source = "${inputs.ttt-plugins}/lsp-c";
        permissions = {
          settings = true;
          settings_keys = [ "lsp.*" ];
        };
      };
      lsp-rust = {
        source = "${inputs.ttt-plugins}/lsp-rust";
        permissions = {
          settings = true;
          settings_keys = [ "lsp.*" ];
        };
      };
      lsp-lua = {
        source = "${inputs.ttt-plugins}/lsp-lua";
        permissions = {
          settings = true;
          settings_keys = [ "lsp.*" ];
        };
      };
      lsp-bash = {
        source = "${inputs.ttt-plugins}/lsp-bash";
        permissions = {
          settings = true;
          settings_keys = [ "lsp.*" ];
        };
      };
      lsp-java = {
        source = "${inputs.ttt-plugins}/lsp-java";
        permissions = {
          settings = true;
          settings_keys = [ "lsp.*" ];
        };
      };
      lsp-markdown = {
        source = "${inputs.ttt-plugins}/lsp-markdown";
        permissions = {
          settings = true;
          settings_keys = [ "lsp.*" ];
        };
      };
      lsp-tailwindcss = {
        source = "${inputs.ttt-plugins}/lsp-tailwindcss";
        permissions = {
          settings = true;
          settings_keys = [ "lsp.*" ];
        };
      };
      # manifest name 必须是 "vim"（registry 按 manifest 的 name 查找）
      vim = {
        source = inputs.ttt-vim;
        permissions = {
          keybindings = true;
          "editor.read" = true;
          "editor.write" = true;
          commands = true;
          "fs.write" = true;
          settings = true;
          settings_keys = [
            "vim.enabled"
            "vim.clipboard"
          ];
        };
      };
    };

    # desktop
    hm-hyprland.enable = true;
    hm-umbriel.enable = false;
    hm-niri.enable = true;
    hm-mango.enable = true;
    theme.enable = true;
    kitty.enable = true;
    chat.enable = true;
    misc.enable = true;
    hmBasePackages.enable = true;
    hmPolkit.enable = true;
    hmScreenshot.enable = true;
    hmSession.enable = true;
    foot.enable = true;
    tofi.enable = true;
    musicfox.enable = true;
    obsStudio.enable = true;
    prismlauncher.enable = true;
    noctalia.enable = true;
    caelestia.enable = false;
    vicinae.enable = true;

    # dev
    meli.enable = true;
    tokens.enable = true;
    opencode.wakatime.enable = true;

    # service
    mpd.enable = true;
    clipse.enable = true;
    mprisence.enable = true;
  };
}
