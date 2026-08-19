{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rhencloud.nixvim;
in
{
  config = mkIf cfg.enable {
    programs.nixvim = {
      viAlias = true;
      vimAlias = true;

      globals = {
        mapleader = " ";
        maplocalleader = " ";
      };

      opts = {
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

      clipboard = {
        register = "unnamedplus";
        providers.wl-copy.enable = true;
      };

      luaConfigPre = ''
        vim.api.nvim_create_augroup("YankHighlight", { clear = true })
      '';

      autoCmd = [
        {
          event = [ "TermOpen" ];
          pattern = [ "*" ];
          command = "startinsert";
        }
        {
          event = [ "TextYankPost" ];
          pattern = [ "*" ];
          group = "YankHighlight";
          callback = {
            __raw = "function() vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 150 }) end";
          };
        }
        {
          event = [ "VimResized" ];
          pattern = [ "*" ];
          command = "tabdo wincmd =";
        }
      ];
    };

    home.packages = with pkgs; [
      nil
      nixfmt
      shellcheck
    ];
  };
}