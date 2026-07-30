{ config, lib, ... }: with lib; mkIf config.rhencloud.nvf.enable {
  programs.nvf.settings.vim.keymaps = [
    # 文件树
    {
      mode = "n";
      key = "<leader>e";
      action = "<cmd>Neotree toggle<CR>";
      desc = "文件树";
    }
    # 诊断面板
    {
      mode = "n";
      key = "<leader>xx";
      action = "<cmd>Trouble diagnostics toggle<CR>";
      desc = "诊断面板";
    }
    {
      mode = "n";
      key = "<leader>xX";
      action = "<cmd>Trouble diagnostics toggle filter.buf=0<CR>";
      desc = "当前文件诊断";
    }
    {
      mode = "n";
      key = "<leader>cs";
      action = "<cmd>Trouble symbols toggle<CR>";
      desc = "符号列表";
    }
    # 窗口导航
    {
      mode = "n";
      key = "<C-h>";
      action = "<C-w>h";
      desc = "左侧窗口";
    }
    {
      mode = "n";
      key = "<C-j>";
      action = "<C-w>j";
      desc = "下侧窗口";
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<C-w>k";
      desc = "上侧窗口";
    }
    {
      mode = "n";
      key = "<C-l>";
      action = "<C-w>l";
      desc = "右侧窗口";
    }
    # 窗口大小调整
    {
      mode = "n";
      key = "<C-Up>";
      action = "<cmd>resize +2<CR>";
      desc = "增高";
    }
    {
      mode = "n";
      key = "<C-Down>";
      action = "<cmd>resize -2<CR>";
      desc = "减高";
    }
    {
      mode = "n";
      key = "<C-Left>";
      action = "<cmd>vertical resize -2<CR>";
      desc = "减宽";
    }
    {
      mode = "n";
      key = "<C-Right>";
      action = "<cmd>vertical resize +2<CR>";
      desc = "增宽";
    }
    # 移动行
    {
      mode = "v";
      key = "J";
      action = ":m '>+1<CR>gv=gv";
      desc = "下移选中行";
    }
    {
      mode = "v";
      key = "K";
      action = ":m '<-2<CR>gv=gv";
      desc = "上移选中行";
    }
    # 滚动居中
    {
      mode = "n";
      key = "<C-d>";
      action = "<C-d>zz";
      desc = "下翻半页";
    }
    {
      mode = "n";
      key = "<C-u>";
      action = "<C-u>zz";
      desc = "上翻半页";
    }
    {
      mode = "n";
      key = "n";
      action = "nzzzv";
      desc = "下一个匹配";
    }
    {
      mode = "n";
      key = "N";
      action = "Nzzzv";
      desc = "上一个匹配";
    }
    # 格式化
    {
      mode = "n";
      key = "<leader>gf";
      action = "<cmd>lua require('conform').format()<CR>";
      desc = "格式化 (conform)";
    }
    # 保存 / 退出
    {
      mode = "n";
      key = "<leader>w";
      action = "<cmd>w<CR>";
      desc = "保存";
    }
    {
      mode = "n";
      key = "<leader>q";
      action = "<cmd>q<CR>";
      desc = "退出";
    }
  ];
}
