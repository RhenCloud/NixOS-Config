{
  pkgs,
  lib,
  config,
  ...
}: with lib; mkIf config.rhencloud.nvf.enable {
  programs.nvf.settings.vim = {
    # ---- Treesitter ----
    treesitter = {
      enable = true;
      context.enable = true;
    };

    # ---- Language modules ----
    languages = {
      nix.enable = true;
      lua.enable = true;
      rust.enable = true;
      python.enable = true;
      go.enable = true;
      typescript.enable = true;
      bash.enable = true;
      json.enable = true;
      yaml.enable = true;
      markdown.enable = true;
      clang.enable = true;
      css.enable = true;
      html.enable = true;
      java.enable = true;
      toml.enable = true;
    };

    # ---- LSP customization ----
    lsp = {
      enable = true;

      mappings = {
        goToDefinition = "gd";
        listReferences = "gD";
        goToType = "gt";
        listImplementations = "gi";
        hover = "K";
        renameSymbol = "<leader>rn";
        codeAction = "<leader>ca";
        nextDiagnostic = "]d";
        previousDiagnostic = "[d";
      };

      lightbulb.enable = true;

      lspSignature = {
        enable = true;
        setupOpts = {
          hint_enable = false;
          max_width = 100;
          handler_opts.border = "rounded";
        };
      };

      # Register typos-lsp as a custom LSP server
      servers = {
        typos_lsp = {
          cmd = [
            (lib.getExe pkgs.typos-lsp)
          ];
          filetypes = [
            "python"
            "rust"
            "nix"
            "go"
            "javascript"
            "typescript"
            "lua"
            "yaml"
            "json"
            "markdown"
            "bash"
            "html"
            "css"
          ];
          root_markers = [
            ".git"
            "pyproject.toml"
            "Cargo.toml"
            "flake.nix"
            "go.mod"
            "package.json"
          ];
          settings.typos_lsp.diagnosticSeverity = "Hint";
        };
      };
    };

    # ---- Formatters ----
    formatter.conform-nvim = {
      enable = true;
      setupOpts = {
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
  };

  home.packages = with pkgs; [
    stylua
    black
    isort
    prettierd
    typos-lsp
  ];
}
