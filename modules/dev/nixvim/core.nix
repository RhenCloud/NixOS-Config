{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhen.nixvim;
in
{
  config = mkIf cfg.enable {
    programs.nixvim = {
      viAlias = true;
      vimAlias = true;

      globals = {
        mapleader = " ";
        maplocalleader = "\\";
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
        termguicolors = true;
        clipboard = lib.mkForce "unnamedplus";
      };

      clipboard.providers.wl-copy.enable = true;

      autoCmd = [
        {
          event = [ "TermOpen" ];
          pattern = [ "*" ];
          command = "startinsert";
        }
        {
          # toggleterm 的 terminal 进程退出后彻底销毁 buffer，避免僵尸终端累积
          # （退出 nvim 时 vim.v.exiting 非零，跳过以免报错）
          event = [ "TermClose" ];
          pattern = [ "*toggleterm*" ];
          group = "ToggleTermCleanup";
          callback = {
            __raw = ''
              function(ev)
                if vim.v.exiting ~= vim.NIL then
                  return
                end
                vim.api.nvim_buf_delete(ev.buf, { force = true })
              end
            '';
          };
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
