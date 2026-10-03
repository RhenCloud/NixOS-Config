{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
mkIf config.rhen.nixvim.enable {
  programs.nixvim = {
    extraConfigLuaPre = ''
      if vim.fn.has("nvim-0.11") == 1 then
        vim.lsp.uri_from_bufnr = vim.uri_from_bufnr
      end
    '';

    plugins.treesitter = {
      enable = true;
      settings.highlight.enable = true;
      settings.indent.enable = true;
    };
    plugins.treesitter-context.enable = true;

    plugins.lsp = {
      enable = true;
      servers = {
        lua_ls = {
          enable = true;
          package = pkgs.lua-language-server;
          settings.Lua = {
            diagnostics.globals = [ "vim" ];
            workspace.checkThirdParty = false;
            telemetry.enable = false;
          };
        };
        nixd = {
          enable = true;
          package = pkgs.nixd;
          settings.formatting.command = [ (lib.getExe pkgs.nixfmt) ];
        };
        bashls = {
          enable = true;
          package = pkgs.bash-language-server;
        };
        pyright = {
          enable = true;
          package = pkgs.pyright;
          # lint/格式由 ruff + conform 负责，pyright 只做补全与跳转
          settings.python.analysis = {
            typeCheckingMode = "off";
            diagnosticMode = "openFilesOnly";
          };
        };
        ts_ls = {
          enable = true;
          package = pkgs.typescript-language-server;
        };
        rust_analyzer = {
          enable = true;
          package = pkgs.rust-analyzer;
          # rustup 管理工具链，cargo/rustc/rustfmt 已在 PATH，无需 nixvim 代装
          installCargo = false;
          installRustc = false;
          installRustfmt = false;
          settings."rust-analyzer".check.command = "clippy";
        };
        clangd = {
          enable = true;
          package = pkgs.clang-tools;
        };
        gopls = {
          enable = true;
          package = pkgs.gopls;
          settings.gopls = {
            staticcheck = true;
            completeUnimported = true;
          };
        };
        jdtls = {
          enable = true;
          package = pkgs.jdt-language-server;
        };
      };
      keymaps.lspBuf = {
        gd = "definition";
        gD = "references";
        gt = "type_definition";
        gi = "implementation";
        K = "hover";
        "<leader>rn" = "rename";
        "<leader>ca" = "code_action";
      };
      keymaps.diagnostic = {
        "]d" = "goto_next";
        "[d" = "goto_prev";
      };
    };

    plugins.lsp-lines.enable = true;

    plugins.lsp-signature = {
      enable = true;
      settings = {
        hint_enable = false;
        max_width = 100;
        handler_opts.border = "rounded";
      };
    };

    plugins.conform-nvim = {
      enable = true;
      settings = {
        # 显式绑定 store 路径，不依赖 PATH（rustfmt/gofmt 走 rustup/go 工具链除外）
        formatters = {
          nixfmt.command = lib.getExe pkgs.nixfmt;
          stylua.command = lib.getExe pkgs.stylua;
          black.command = lib.getExe pkgs.black;
          isort.command = lib.getExe pkgs.isort;
          prettierd.command = lib.getExe pkgs.prettierd;
        };
        formatters_by_ft = {
          nix = [ "nixfmt" ];
          lua = [ "stylua" ];
          python = [
            "isort"
            "black"
          ];
          rust = [ "rustfmt" ];
          go = [ "gofmt" ];
          javascript = [ "prettierd" ];
          typescript = [ "prettierd" ];
          json = [ "prettierd" ];
          yaml = [ "prettierd" ];
          markdown = [ "prettierd" ];
          html = [ "prettierd" ];
          css = [ "prettierd" ];
          "*" = [ "trim_whitespace" ];
        };
        format_on_save = {
          lsp_fallback = true;
          timeout_ms = 1000;
        };
      };
    };

    extraConfigLua = ''
      vim.lsp.config('typos_lsp', {
        cmd = { "${lib.getExe pkgs.typos-lsp}" },
        filetypes = { "python", "rust", "nix", "go", "javascript", "typescript", "lua", "yaml", "json", "markdown", "bash", "html", "css" },
        root_dir = function(bufnr)
          return vim.fs.root(bufnr, { ".git", "pyproject.toml", "Cargo.toml", "flake.nix", "go.mod", "package.json" })
        end,
        settings = {
          typos_lsp = {
            diagnosticSeverity = "Hint",
          },
        },
      })
      vim.lsp.enable('typos_lsp')
    '';
  };

  home.packages = with pkgs; [
    stylua
    black
    isort
    prettierd
    typos-lsp
  ];
}
