{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhen.ttt;

  pluginFiles = mapAttrsToList (name: plugin: {
    name = "ttt/plugins/${name}";
    value.source = plugin.source;
  }) cfg.plugins;

  pluginRegistry = mapAttrsToList (name: plugin: {
    inherit name;
    version = "";
    enabled = plugin.enabled;
    permissions = plugin.permissions;
  }) cfg.plugins;
in
{
  options.rhen.ttt = {
    enable = mkEnableOption "TTT editor";

    settings = mkOption {
      type = types.attrs;
      default = {
        version = 1;
        # dracula 是 TTT 内置主题（go:embed themes/dracula.json，
        # 带完整 VS Code tokenColors，代码高亮与官方 Dracula 一致）；
        # TTT 解析主题先查 ~/.config/ttt/themes/ 再查内嵌，无需落盘 json
        theme = "dracula";
        appearance = {
          icons = "nerd-font";
          chevrons = {
            collapsed = ">";
            expanded = "v";
          };
        };
        editor = {
          tabSize = 4;
          insertSpaces = true;
          wordWrap = false;
          diffMode = "split";
          diffContext = "changes";
          diffWordWrap = false;
          lineNumbers = true;
          formatOnSave = true;
          insertFinalNewline = true;
          trimTrailingWhitespace = false;
          focusOnOpen = false;
          gutterStyle = "compact";
          borderStyle = "default";
          bracketPairColorization = false;
          transparentBackground = false;
        };
        search.debounce = 350;
        explorer = {
          showHidden = true;
          showGitIgnored = true;
          gitStatusColors = true;
          dimStagedGitColors = false;
        };
        git.fileView = "list";
        terminal.scrollback = 1000;
        lsp = {
          saveOnRename = false;
          hoverDelay = 500;
          servers = {
            nix = {
              command = [ "nixd" ];
              languages.".nix" = "nix";
            };
            bash = {
              command = [
                "bash-language-server"
                "start"
              ];
              languages = {
                ".sh" = "shellscript";
                ".bash" = "shellscript";
                ".zsh" = "shellscript";
                ".fish" = "shellscript";
              };
            };
            python = {
              # ruff server 不提供补全（只有诊断/quickfix/hover），
              # 所以补全/跳转用 basedpyright；ruff 保留在 formatters.py 做保存时格式化。
              # 注：TTT 每个语言只解析到一个 LSP server，勿再为 .py 添加第二个 server 条目。
              command = [
                "basedpyright-langserver"
                "--stdio"
              ];
              languages.".py" = "python";
            };
            typescript = {
              command = [
                "typescript-language-server"
                "--stdio"
              ];
              languages = {
                ".ts" = "typescript";
                ".tsx" = "typescriptreact";
                ".js" = "javascript";
                ".jsx" = "javascriptreact";
                ".mjs" = "javascript";
                ".mts" = "typescript";
                ".cjs" = "javascript";
                ".cts" = "typescript";
              };
            };
            rust = {
              command = [ "rust-analyzer" ];
              languages.".rs" = "rust";
            };
            go = {
              command = [ "gopls" ];
              languages.".go" = "go";
            };
            c = {
              command = [ "clangd" ];
              languages = {
                ".c" = "c";
                ".h" = "c";
                ".cc" = "cpp";
                ".cpp" = "cpp";
                ".cxx" = "cpp";
                ".hpp" = "cpp";
              };
            };
            lua = {
              command = [ "lua-language-server" ];
              languages.".lua" = "lua";
            };
            java = {
              command = [ "jdtls" ];
              languages.".java" = "java";
            };
            # 以下两项与 lsp-markdown / lsp-tailwindcss 插件的 on_install 等价
            # （钩子无法写入 HM 管理的只读 settings.json，故在此声明）
            markdown = {
              command = [
                "marksman"
                "server"
              ];
              languages.".md" = "markdown";
            };
            tailwindcss = {
              command = [
                "tailwindcss-language-server"
                "--stdio"
              ];
              # 注意：.ts/.js 等扩展名已被 typescript server 认领，
              # 这里不要再声明（扩展名解析是随机 map 序，一个扩展名只能归一个 server）
              languages = {
                ".css" = "css";
                ".html" = "html";
              };
            };
          };
        };
        autocomplete = {
          enabled = true;
          autoSuggest = true;
          debounce = 150;
          signatureHelp = true;
        };
        markdown.wrapWidth = 80;
        image.protocol = "auto";
        formatters = {
          nix = "nixfmt";
          js = "prettierd --stdin-filepath {file}";
          jsx = "prettierd --stdin-filepath {file}";
          ts = "prettierd --stdin-filepath {file}";
          tsx = "prettierd --stdin-filepath {file}";
          json = "prettierd --stdin-filepath {file}";
          yaml = "prettierd --stdin-filepath {file}";
          yml = "prettierd --stdin-filepath {file}";
          md = "prettierd --stdin-filepath {file}";
          html = "prettierd --stdin-filepath {file}";
          css = "prettierd --stdin-filepath {file}";
          # 与 formatter-ruff 插件目标一致（此前是 black，且 black 并未安装）
          py = "ruff format --stdin-filename {file} -";
          lua = "stylua -";
          sh = "shfmt";
          bash = "shfmt";
          zsh = "shfmt";
          fish = "shfmt";
        };
      };
      description = "TTT settings.json content";
    };

    keybindings = mkOption {
      type = types.nullOr (
        types.attrsOf (
          types.oneOf [
            types.str
            types.package
            (types.listOf (
              types.oneOf [
                types.str
                types.package
              ]
            ))
          ]
        )
      );
      default = null;
      description = "TTT keybindings.json content (dict override format); null keeps TTT built-in keybindings";
    };

    themes = mkOption {
      type = types.attrsOf types.path;
      default = { };
      description = "Declaratively managed TTT themes";
    };

    plugins = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            source = mkOption {
              type = types.oneOf [
                types.path
                types.str
              ];
              description = "Directory containing plugin.ttt.json and plugin Lua files";
            };
            enabled = mkOption {
              type = types.bool;
              default = true;
              description = "Whether TTT loads the plugin";
            };
            permissions = mkOption {
              type = types.attrsOf types.anything;
              default = { };
              description = "Permissions pre-approved for this plugin";
            };
          };
        }
      );
      default = { };
      description = "Read-only TTT plugins managed from Nix store sources";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.ttt
      # lsp-markdown / lsp-tailwindcss 插件对应的语言服务器
      #（nixvim 的 languages.nix 只管编辑器侧，这里由 TTT 模块自带）
      pkgs.marksman
      pkgs.tailwindcss-language-server
    ];

    xdg.configFile = {
      "ttt/settings.json".text = builtins.toJSON cfg.settings;
      "ttt/plugins.ttt.json".text = builtins.toJSON pluginRegistry;
      "ttt/themes/36-amethyst.json".source = "${inputs.ttt}/config/themes/36-amethyst.json";
    }
    // optionalAttrs (cfg.keybindings != null) {
      "ttt/keybindings.json".text = builtins.toJSON cfg.keybindings;
    }
    // mapAttrs' (name: source: nameValuePair "ttt/themes/${name}.json" { inherit source; }) cfg.themes
    // listToAttrs pluginFiles;
  };
}
