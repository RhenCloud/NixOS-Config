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
        options.component_separators = {
          left = "│";
          right = "│";
        };
        options.section_separators = {
          left = "";
          right = "";
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
      settings = {
        close_if_last_window = true;
        filesystem = {
          filtered_items = {
            hide_dotfiles = false;
            hide_gitignored = true;
            hide_hidden = false;
          };
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
    };

    plugins.aerial = {
      enable = true;
      settings.backends = [
        "treesitter"
        "lsp"
      ];
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

    plugins.undotree.enable = true;

    plugins.mini = {
      enable = true;
      modules.surround = { };
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
    {
      mode = "n";
      key = "]h";
      action = "<cmd>Gitsigns next_hunk<CR>";

    }
    {
      mode = "n";
      key = "[h";
      action = "<cmd>Gitsigns prev_hunk<CR>";

    }
    {
      mode = "n";
      key = "<leader>gs";
      action = "<cmd>Gitsigns stage_hunk<CR>";

    }
    {
      mode = "n";
      key = "<leader>gS";
      action = "<cmd>Gitsigns stage_buffer<CR>";

    }
    {
      mode = "n";
      key = "<leader>gu";
      action = "<cmd>Gitsigns undo_stage_hunk<CR>";

    }
    {
      mode = "n";
      key = "<leader>gb";
      action = "<cmd>Gitsigns blame_line<CR>";

    }
    {
      mode = "n";
      key = "<leader>gd";
      action = "<cmd>Gitsigns diffthis<CR>";

    }
    {
      mode = "n";
      key = "<leader>gD";
      action = "<cmd>Gitsigns toggle_deleted<CR>";

    }
    {
      mode = "n";
      key = "<leader>gp";
      action = "<cmd>Gitsigns preview_hunk<CR>";

    }
    {
      mode = "n";
      key = "<leader>xx";
      action = "<cmd>Trouble diagnostics toggle<CR>";
      options.desc = "诊断面板";
    }
    {
      mode = "n";
      key = "<leader>xX";
      action = "<cmd>Trouble diagnostics toggle filter.buf=0<CR>";
      options.desc = "当前文件诊断";
    }
    {
      mode = "n";
      key = "<leader>cs";
      action = "<cmd>Trouble symbols toggle<CR>";
      options.desc = "符号列表";
    }
    {
      mode = "n";
      key = "<leader>a";
      action = "<cmd>AerialToggle<CR>";
      options.desc = "代码大纲";
    }
    {
      mode = "n";
      key = "s";
      action = {
        __raw = "function() require('flash').jump() end";
      };
      options.desc = "Flash 跳转";
    }
    {
      mode = "n";
      key = "S";
      action = {
        __raw = "function() require('flash').treesitter() end";
      };
      options.desc = "Flash Treesitter";
    }
    {
      mode = "n";
      key = "<leader>r";
      action = {
        __raw = "function() require('flash').remote() end";
      };
      options.desc = "Flash 远程";
    }
  ];
}
