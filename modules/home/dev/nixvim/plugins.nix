{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.rhencloud.nixvim;
in
mkIf cfg.enable {
  programs.nixvim = {
    plugins.cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        mapping = {
          "<C-n>" = "cmp.mapping.select_next_item()";
          "<C-p>" = "cmp.mapping.select_prev_item()";
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<C-e>" = "cmp.mapping.abort()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<Tab>" = "cmp.mapping.confirm({ select = true })";
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
        options.component_separators = { left = "│"; right = "│"; };
        options.section_separators = { left = ""; right = ""; };
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
      keymaps = {
        nextHunk = "]h";
        previousHunk = "[h";
        stageHunk = "<leader>gs";
        stageBuffer = "<leader>gS";
        undoStageHunk = "<leader>gu";
        blameLine = "<leader>gb";
        diffThis = "<leader>gd";
        toggleDeleted = "<leader>gD";
        previewHunk = "<leader>gp";
      };
    };

    plugins.which-key = {
      enable = true;
      settings.spec = [
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
          __unkeyed-1 = "<leader>o";
          group = "Oil 文件";
        }
      ];
    };

    plugins.neo-tree = {
      enable = true;
      closeIfLastWindow = true;
      filesystem = {
        filteredItems = {
          hideDotfiles = false;
          hideGitignored = true;
          hideHidden = false;
        };
      };
    };

    plugins.toggleterm = {
      enable = true;
      settings = {
        direction = "float";
        float_opts.border = "curved";
      };
    };

    plugins.noice = {
      enable = true;
      settings = {
        lsp.override = {
          "vim.lsp.util.convert_input_to_markdown_lines" = true;
          "vim.lsp.util.stylize_markdown" = true;
        };
        presets = {
          bottom_search = true;
          command_palette = true;
          long_message_to_split = true;
        };
      };
    };

    plugins.trouble = {
      enable = true;
      keymaps = {
        documentDiagnostics = "<leader>xX";
        workspaceDiagnostics = "<leader>xx";
        symbols = "<leader>cs";
      };
    };

    plugins.aerial = {
      enable = true;
      settings.backends = [ "treesitter" "lsp" ];
      keymaps = {
        toggle = "<leader>a";
      };
    };

    plugins.flash = {
      enable = true;
      settings = {
        labels = "asdfghjklqwertyuiopzxcvbnm";
        modes.search.enabled = true;
        modes.char.enabled = true;
      };
      keymaps = {
        jump = "s";
        treesitter = "S";
        remote = "<leader>r";
      };
    };

    plugins.undotree.enable = true;

    plugins.mini = {
      enable = true;
      modules.surround = { };
    };

    plugins.fidget = {
      enable = true;
      settings = {
        progress.polling_rate = 0;
        notification.override_vim_notify = true;
      };
    };

    plugins.nvim-autopairs.enable = true;

    plugins.comment-nvim = {
      enable = true;
      settings.toggler.line = "gcc";
      settings.toggler.block = "gbc";
    };

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

    plugins.auto-session = {
      enable = true;
      settings = {
        auto_save_enabled = true;
        auto_restore_enabled = true;
        auto_create_enabled = true;
        suppressed_dirs = [ "/" "/tmp" "/etc" ];
      };
    };
  };

  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>o";
      action = "<cmd>Oil<CR>";
      options.desc = "Oil 文件浏览器";
    }
    {
      mode = "n";
      key = "<leader>u";
      action = "<cmd>UndotreeToggle<CR>";
      options.desc = "撤销树";
    }
  ];
}