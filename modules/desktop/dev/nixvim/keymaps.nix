{ config, lib, ... }:
with lib;
mkIf config.rhencloud.nixvim.enable {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>Neotree toggle<CR>";
      options.desc = "文件树";
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
      options.desc = "下一个匹配";
    }
    {
      mode = "n";
      key = "N";
      action = "Nzzzv";
      options.desc = "上一个匹配";
    }
    {
      mode = "n";
      key = "<leader>gf";
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
  ];
}
