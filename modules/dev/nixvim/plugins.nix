{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.nixvim;
in
mkIf cfg.enable {
  programs.nixvim = {
    colorscheme = "dracula";

    colorschemes.dracula-nvim.enable = true;

    plugins.luasnip = {
      enable = true;
      fromVscode = [ { } ]; # friendly-snippets
    };

    plugins.friendly-snippets.enable = true;

    plugins.cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
        mapping = {
          "<C-n>" = "cmp.mapping.select_next_item()";
          "<C-p>" = "cmp.mapping.select_prev_item()";
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<C-e>" = "cmp.mapping.abort()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<Tab>" =
            "cmp.mapping(function(fallback)
            local luasnip = require('luasnip')
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' })";
          "<S-Tab>" =
            "cmp.mapping(function(fallback)
            local luasnip = require('luasnip')
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' })";
        };
        sources = [
          { name = "nvim_lsp"; }
          { name = "luasnip"; }
          { name = "path"; }
          { name = "buffer"; }
          { name = "nvim_lsp_signature_help"; }
        ];
      };
    };

    plugins.telescope = {
      enable = true;
      keymaps = {
        "<leader>ff" = "find_files";
        "<leader>fg" = "live_grep";
        "<leader>fb" = "buffers";
        "<leader>fh" = "help_tags";
        "<leader>fd" = "diagnostics";
      };
      settings.defaults.file_ignore_patterns = [
        "node_modules"
        ".git/"
        "target/"
        "result/"
        "__pycache__"
      ];
    };

    plugins.lualine = {
      enable = true;
      settings = {
        options = {
          theme = "dracula";
          component_separators = {
            left = "│";
            right = "│";
          };
          section_separators = {
            left = "";
            right = "";
          };
        };
      };
    };

    plugins.gitsigns = {
      enable = true;
      settings = {
        current_line_blame = true;
        current_line_blame_opts = {
          delay = 500;
          virtual_text_pos = "eol";
        };
      };
    };

    plugins.which-key = {
      enable = true;
      settings = {
        delay = 0;
        spec = [
          {
            __unkeyed-1 = "<leader>f";
            group = "查找 / Telescope";
          }
          {
            __unkeyed-1 = "<leader>c";
            group = "代码 / Code";
          }
          {
            __unkeyed-1 = "<leader>g";
            group = "Git";
          }
          {
            __unkeyed-1 = "<leader>w";
            group = "窗口 / Window";
          }
          {
            __unkeyed-1 = "<leader>x";
            group = "诊断 / Trouble";
          }
          {
            __unkeyed-1 = "<leader>e";
            group = "Oil 文件";
          }
          {
            __unkeyed-1 = "<leader>t";
            group = "终端 / Terminal";
          }
          {
            __unkeyed-1 = "<leader>b";
            group = "Buffer";
          }
          {
            __unkeyed-1 = "<leader>d";
            group = "文档 / Docs";
          }
          {
            __unkeyed-1 = "<localleader>";
            group = "+本地 leader（语言）";
          }
        ];
      };
    };

    plugins.toggleterm = {
      enable = true;
      settings = {
        direction = "float";
        float_opts.border = "curved";
      };
    };
    plugins.trouble = {
      enable = true;
    };

    plugins.flash = {
      enable = true;
      settings = {
        labels = "asdfghjklqwertyuiopzxcvbnm";
        modes = {
          search.enabled = true;
          char.enabled = true;
        };
      };
    };

    plugins.mini = {
      enable = true;
      modules = {
        surround = { };
        pick = { };
        tabline = { };
      };
    };

    plugins.fidget = {
      enable = true;
      settings = {
        notification.override_vim_notify = true;
      };
    };

    plugins.nvim-autopairs.enable = true;

    plugins.render-markdown.enable = true;

    plugins.comment.enable = true;

    plugins.todo-comments = {
      enable = true;
      settings.signs = false;
    };

    plugins.indent-blankline = {
      enable = true;
      settings.scope.enabled = false;
    };

    plugins.web-devicons.enable = true;

    plugins.colorizer.enable = true;

    plugins.notify = {
      enable = true;
      settings.level = "warn";
    };

    plugins.oil = {
      enable = true;
      settings = {
        default_file_explorer = true;
        columns = {
          icon = "icon";
          permissions = "permissions";
          size = "size";
        };
        keymaps = {
          "g?" = "show_help";
          "<C-s>" = "actions.select_split";
          "<C-v>" = "actions.select_vsplit";
        };
      };
    };

    plugins.dressing = {
      enable = true;
      settings = {
        input = {
          relative = "win";
          prefer_width = 40;
        };
        select = {
          backend = [
            "telescope"
            "builtin"
          ];
        };
      };
    };

    plugins.neogen = {
      enable = true;
      keymaps.generate = "<leader>dn";
    };

    plugins.dial.enable = true;

    plugins.lint = {
      enable = true;
      # 保存时触发（autoCmd 默认 BufWritePost → try_lint）
      linters = {
        ruff.cmd = lib.getExe pkgs.ruff;
        eslint.cmd = lib.getExe pkgs.eslint_d;
      };
      # 整体覆写：nixvim 默认表含未安装的 vale/jsonlint 等
      lintersByFt = {
        python = [ "ruff" ];
        javascript = [ "eslint" ];
        typescript = [ "eslint" ];
      };
    };

    plugins.auto-session = {
      enable = true;
      settings = {
        auto_save_enabled = true;
        auto_restore_enabled = true;
        auto_create_enabled = true;
        suppressed_dirs = [
          "/"
          "/tmp"
          "/etc"
        ];
      };
    };
  };
}
