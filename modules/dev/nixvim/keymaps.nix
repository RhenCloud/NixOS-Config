{ config, lib, ... }:
with lib;
mkIf config.rhen.nixvim.enable {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>Oil<CR>";
      options.desc = "文件浏览 (Oil)";
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
      key = "<C-h>";
      action = "<C-w>h";
      options.desc = "左侧窗口";
    }
    {
      mode = "n";
      key = "<C-j>";
      action = "<C-w>j";
      options.desc = "下侧窗口";
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<C-w>k";
      options.desc = "上侧窗口";
    }
    {
      mode = "n";
      key = "<C-l>";
      action = "<C-w>l";
      options.desc = "右侧窗口";
    }
    {
      mode = "n";
      key = "<C-Up>";
      action = "<cmd>resize +2<CR>";
      options.desc = "增高";
    }
    {
      mode = "n";
      key = "<C-Down>";
      action = "<cmd>resize -2<CR>";
      options.desc = "减高";
    }
    {
      mode = "n";
      key = "<C-Left>";
      action = "<cmd>vertical resize -2<CR>";
      options.desc = "减宽";
    }
    {
      mode = "n";
      key = "<C-Right>";
      action = "<cmd>vertical resize +2<CR>";
      options.desc = "增宽";
    }
    {
      mode = "v";
      key = "J";
      action = ":m '>+1<CR>gv=gv";
      options.desc = "下移选中行";
    }
    {
      mode = "v";
      key = "K";
      action = ":m '<-2<CR>gv=gv";
      options.desc = "上移选中行";
    }
    {
      mode = "n";
      key = "<C-d>";
      action = "<C-d>zz";
      options.desc = "下翻半页";
    }
    {
      mode = "n";
      key = "<C-u>";
      action = "<C-u>zz";
      options.desc = "上翻半页";
    }
    {
      mode = "n";
      key = "n";
      action = "nzzzv";
      options = {
        desc = "下一个匹配";
        nowait = true;
      };
    }
    {
      mode = "n";
      key = "N";
      action = "Nzzzv";
      options = {
        desc = "上一个匹配";
        nowait = true;
      };
    }
    {
      mode = "n";
      key = "<leader>cf";
      action = "<cmd>lua require('conform').format()<CR>";
      options.desc = "格式化 (conform)";
    }
    {
      mode = "n";
      key = "<leader>w";
      action = "<cmd>w<CR>";
      options.desc = "保存";
    }
    {
      mode = "n";
      key = "<leader>q";
      action = "<cmd>q<CR>";
      options.desc = "退出";
    }

    # ── Gitsigns ──────────────────────────────────────────
    {
      mode = "n";
      key = "]h";
      action = "<cmd>Gitsigns next_hunk<CR>";
      options.desc = "下一个 hunk";
    }
    {
      mode = "n";
      key = "[h";
      action = "<cmd>Gitsigns prev_hunk<CR>";
      options.desc = "上一个 hunk";
    }
    {
      mode = "n";
      key = "<leader>gs";
      action = "<cmd>Gitsigns stage_hunk<CR>";
      options.desc = "暂存 hunk";
    }
    {
      mode = "n";
      key = "<leader>gS";
      action = "<cmd>Gitsigns stage_buffer<CR>";
      options.desc = "暂存整个 buffer";
    }
    {
      mode = "n";
      key = "<leader>gu";
      action = "<cmd>Gitsigns undo_stage_hunk<CR>";
      options.desc = "撤销暂存";
    }
    {
      mode = "n";
      key = "<leader>gb";
      action = "<cmd>Gitsigns blame_line<CR>";
      options.desc = "当前行 blame";
    }
    {
      mode = "n";
      key = "<leader>gd";
      action = "<cmd>Gitsigns diffthis<CR>";
      options.desc = "diff 当前文件";
    }
    {
      mode = "n";
      key = "<leader>gD";
      action = "<cmd>Gitsigns toggle_deleted<CR>";
      options.desc = "显示/隐藏删除行";
    }
    {
      mode = "n";
      key = "<leader>gp";
      action = "<cmd>Gitsigns preview_hunk<CR>";
      options.desc = "预览 hunk";
    }

    # ── Flash ─────────────────────────────────────────────
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

    # ── ToggleTerm ────────────────────────────────────────
    {
      mode = "n";
      key = "<leader>tt";
      action = "<cmd>ToggleTerm direction=float<CR>";
      options.desc = "浮动终端";
    }
    {
      mode = "n";
      key = "<leader>th";
      action = "<cmd>ToggleTerm direction=horizontal<CR>";
      options.desc = "横向终端";
    }
    {
      mode = "n";
      key = "<leader>tv";
      action = "<cmd>ToggleTerm direction=vertical<CR>";
      options.desc = "纵向终端";
    }
    {
      mode = "t";
      key = "<Esc><Esc>";
      action = "<cmd>close<CR>";
      options.desc = "退出终端 insert 模式";
    }

    # ── Buffer 导航 ───────────────────────────────────────
    {
      mode = "n";
      key = "<Tab>";
      action = "<cmd>bnext<CR>";
      options.desc = "下一个 buffer";
    }
    {
      mode = "n";
      key = "<S-Tab>";
      action = "<cmd>bprevious<CR>";
      options.desc = "上一个 buffer";
    }
    {
      mode = "n";
      key = "<leader>bb";
      action = "<cmd>lua MiniPick.buffers(nil, { show_buffers = 'listed' })<CR>";
      options.desc = "Buffer 列表 (mini.pick)";
    }
    {
      mode = "n";
      key = "<leader>bd";
      action = "<cmd>bdelete<CR>";
      options.desc = "关闭当前 buffer";
    }

    # ── 窗口管理 ──────────────────────────────────────────
    {
      mode = "n";
      key = "<leader>wv";
      action = "<cmd>vsplit<CR>";
      options.desc = "垂直分屏";
    }
    {
      mode = "n";
      key = "<leader>ws";
      action = "<cmd>split<CR>";
      options.desc = "水平分屏";
    }
    {
      mode = "n";
      key = "<leader>ww";
      action = "<C-w>=";
      options.desc = "窗口等宽/等高等分";
    }
    {
      mode = "n";
      key = "<leader>wh";
      action = "zH";
      options.desc = "向左横滚";
    }
    {
      mode = "n";
      key = "<leader>wl";
      action = "zL";
      options.desc = "向右横滚";
    }

    # ── localleader（\）───────────────────────────────────
    {
      mode = "n";
      key = "<localleader>c";
      action = "<cmd>TSContext toggle<CR>";
      options.desc = "Treesitter 上下文钉住 开/关";
    }

    # ── Dial 数字增减 ─────────────────────────────────────
    {
      mode = [
        "n"
        "v"
      ];
      key = "<A-a>";
      action = {
        __raw = "function() require('dial').map('increment', 'i') end";
      };
      options.desc = "数字 +1";
    }
    {
      mode = [
        "n"
        "v"
      ];
      key = "<A-x>";
      action = {
        __raw = "function() require('dial').map('decrement', 'i') end";
      };
      options.desc = "数字 -1";
    }
  ];
}
