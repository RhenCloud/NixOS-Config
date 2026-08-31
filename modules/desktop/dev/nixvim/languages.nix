{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
mkIf config.rhencloud.nixvim.enable {
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
