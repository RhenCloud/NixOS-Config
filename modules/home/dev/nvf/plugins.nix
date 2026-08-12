{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
  cfg = config.rhencloud.nvf;
in
with lib;
mkIf cfg.enable {
  programs.nvf.settings.vim = {
    # ---- Completion (nvim-cmp) ----
    autocomplete = {
      enableSharedCmpSources = true;
      nvim-cmp = {
        enable = true;
        setupOpts = {
          mapping = lib.mkForce {
            "<C-n>" = mkLuaInline "cmp.mapping.select_next_item()";
            "<C-p>" = mkLuaInline "cmp.mapping.select_prev_item()";
            "<C-b>" = mkLuaInline "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = mkLuaInline "cmp.mapping.scroll_docs(4)";
            "<C-e>" = mkLuaInline "cmp.mapping.abort()";
            "<CR>" = mkLuaInline "cmp.mapping.confirm({ select = true })";
            "<Tab>" = mkLuaInline "cmp.mapping.confirm({ select = true })";
          };
          sources = lib.mkForce [
            { name = "nvim_lsp"; }
            { name = "luasnip"; }
            { name = "path"; }
            { name = "buffer"; }
            { name = "nvim_lsp_signature_help"; }
          ];
        };
        sourcePlugins = with pkgs.vimPlugins; [
          cmp-nvim-lsp
          luasnip
          cmp-path
          cmp-buffer
        ];
      };
    };

    # ---- Telescope ----
    telescope = {
      enable = true;
      mappings = {
        findFiles = "<leader>ff";
        liveGrep = "<leader>fg";
        buffers = "<leader>fb";
        helpTags = "<leader>fh";
        diagnostics = "<leader>fd";
      };
      setupOpts.defaults.file_ignore_patterns = [
        "node_modules"
        ".git/"
        "target/"
        "result/"
        "__pycache__"
      ];
    };

    # ---- Statusline (Lualine) ----
    statusline.lualine = {
      enable = true;
      componentSeparator = {
        left = "│";
        right = "│";
      };
      sectionSeparator = {
        left = "";
        right = "";
      };
    };

    # ---- Git (Gitsigns) ----
    git = {
      enable = true;
      gitsigns = {
        enable = true;
        setupOpts = {
          current_line_blame = true;
          current_line_blame_opts = {
            delay = 500;
            virtual_text_pos = "eol";
          };
        };
        mappings = {
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
    };

    # ---- Which-Key ----
    binds.whichKey = {
      enable = true;
      register = {
        "<leader>f" = "查找 / Telescope";
        "<leader>c" = "代码 / Code";
        "<leader>g" = "Git";
        "<leader>w" = "窗口 / Window";
        "<leader>x" = "诊断 / Trouble";
        "<leader>o" = "Oil 文件";
      };
    };

    # ---- File Tree (Neo-tree) ----
    filetree.neo-tree = {
      enable = true;
      setupOpts = {
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

    # ---- Terminal (Toggleterm) ----
    terminal.toggleterm = {
      enable = true;
      setupOpts = {
        direction = "float";
        float_opts.border = "curved";
      };
    };

    # ---- UI (Noice) ----
    ui.noice = {
      enable = true;
      setupOpts = {
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

    # ---- Diagnostics (Trouble) ----
    lsp.trouble = {
      enable = true;
      mappings = {
        documentDiagnostics = "<leader>xX";
        workspaceDiagnostics = "<leader>xx";
        symbols = "<leader>cs";
      };
    };

    # ---- Outline (Aerial) ----
    utility = {
      outline.aerial-nvim = {
        enable = true;
        setupOpts.backends = [
          "treesitter"
          "lsp"
        ];
        mappings.toggle = "<leader>a";
      };

      # ---- Flash ----
      motion.flash-nvim = {
        enable = true;
        setupOpts.labels = "asdfghjklqwertyuiopzxcvbnm";
        mappings = {
          jump = "s";
          treesitter = "S";
          remote = "<leader>r";
        };
      };

      # ---- Undotree ----
      undotree.enable = true;
    };

    # ---- Mini.surround ----
    mini.surround.enable = true;

    # ---- Fidget ----
    visuals.fidget-nvim = {
      enable = true;
      setupOpts = {
        progress.poll_rate = 0;
        notification.override_vim_notify = true;
      };
    };

    # ---- Auto-pairs ----
    autopairs.nvim-autopairs.enable = true;

    # ---- Comment ----
    comments.comment-nvim.enable = true;

    # ---- Todo Comments ----
    notes.todo-comments = {
      enable = true;
      setupOpts.signs = false;
    };

    # ---- Visuals ----
    visuals = {
      indent-blankline = {
        enable = true;
        setupOpts.scope.enabled = false;
      };
      nvim-web-devicons.enable = true;
    };

    # ---- Colorizer ----
    ui.colorizer.enable = true;

    # ---- Notify ----
    notify.nvim-notify = {
      enable = true;
      setupOpts.level = "warn";
    };

    # ---- Oil ----
    utility.oil-nvim = {
      enable = true;
      setupOpts = {
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

    # ---- Auto-session (via extraPlugins) ----
    extraPlugins.auto-session = {
      package = pkgs.vimPlugins.auto-session;
      setup = ''
        require('auto-session').setup {
          auto_save_enabled = true,
          auto_restore_enabled = true,
          auto_create_enabled = true,
          suppressed_dirs = { "/", "/tmp", "/etc" },
        }
      '';
    };
  };

  # ---- Oil keymap (needs to be here since it references the oil plugin) ----
  programs.nvf.settings.vim.keymaps = [
    {
      mode = "n";
      key = "<leader>o";
      action = "<cmd>Oil<CR>";
      desc = "Oil 文件浏览器";
    }
    {
      mode = "n";
      key = "<leader>u";
      action = "<cmd>UndotreeToggle<CR>";
      desc = "撤销树";
    }
  ];
}
