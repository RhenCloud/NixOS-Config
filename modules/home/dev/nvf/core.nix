{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
in
{
  programs.nvf = {
    enable = true;

    settings.vim = {
      viAlias = true;
      vimAlias = true;

      globals = {
        mapleader = " ";
        maplocalleader = " ";
      };

      options = {
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
        expandtab = true;
        smartindent = true;
        ignorecase = true;
        smartcase = true;
        signcolumn = "yes";
        cursorline = true;
        scrolloff = 8;
        sidescrolloff = 8;
        swapfile = false;
        backup = false;
        undofile = true;
        splitbelow = true;
        splitright = true;
        completeopt = "menu,menuone,noselect";
        updatetime = 300;
        mouse = "a";
        wrap = false;
        clipboard = lib.mkForce "unnamedplus";
      };

      clipboard.enable = true;

      theme = {
        enable = true;
        name = "dracula";
      };

      luaConfigPre = ''
        vim.api.nvim_create_augroup("YankHighlight", { clear = true })
      '';

      autocmds = [
        {
          event = [ "TermOpen" ];
          pattern = [ "*" ];
          command = "startinsert";
        }
        {
          event = [ "TextYankPost" ];
          pattern = [ "*" ];
          group = "YankHighlight";
          callback = mkLuaInline "function() vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 150 }) end";
        }
        {
          event = [ "VimResized" ];
          pattern = [ "*" ];
          command = "tabdo wincmd =";
        }
      ];
    };
  };

  home.packages = with pkgs; [
    nil
    nixfmt
    shellcheck
  ];
}
