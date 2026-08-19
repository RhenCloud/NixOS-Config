{ pkgs, lib, config, ... }:
with lib;
mkIf config.rhencloud.nixvim.enable {
  programs.nixvim = {
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
          python = [ "isort" "black" ];
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
      require('lspconfig').typos_lsp.setup({
        cmd = { "${lib.getExe pkgs.typos-lsp}" },
        filetypes = { "python", "rust", "nix", "go", "javascript", "typescript", "lua", "yaml", "json", "markdown", "bash", "html", "css" },
        root_dir = require('lspconfig').util.root_pattern(".git", "pyproject.toml", "Cargo.toml", "flake.nix", "go.mod", "package.json"),
        settings = {
          typos_lsp = {
            diagnosticSeverity = "Hint",
          },
        },
      })
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