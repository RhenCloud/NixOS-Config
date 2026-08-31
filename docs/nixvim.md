# NVF 使用指南

## 目录

- [基本操作](#基本操作)
- [快捷键大全](#快捷键大全)
- [插件功能](#插件功能)
- [LSP 配置](#lsp-配置)
- [常见问题](#常见问题)

---

## 基本操作

### 编辑模式

| 按键    | 功能           |
| ------- | -------------- |
| `i`     | 进入插入模式   |
| `v`     | 进入可视模式   |
| `V`     | 进入行可视模式 |
| `<C-v>` | 进入块可视模式 |
| `Esc`   | 返回普通模式   |

### 窗口管理

| 快捷键      | 功能           |
| ----------- | -------------- |
| `<C-h>`     | 切换到左侧窗口 |
| `<C-j>`     | 切换到下侧窗口 |
| `<C-k>`     | 切换到上侧窗口 |
| `<C-l>`     | 切换到右侧窗口 |
| `<C-Up>`    | 增高当前窗口   |
| `<C-Down>`  | 减高当前窗口   |
| `<C-Left>`  | 减宽当前窗口   |
| `<C-Right>` | 增宽当前窗口   |

### 文件操作

| 快捷键       | 功能                  |
| ------------ | --------------------- |
| `<leader>w`  | 保存文件              |
| `<leader>q`  | 退出当前窗口          |
| `<leader>ff` | Telescope 查找文件    |
| `<leader>e`  | 切换文件树 (Neo-tree) |

### 光标导航

| 快捷键      | 功能                                   |
| ----------- | -------------------------------------- |
| `s`         | Flash 跳转 — 输入目标字符快速定位      |
| `S`         | Flash Treesitter 跳转 — 按语法节点跳转 |
| `<leader>r` | Flash 远程操作 — 选中目标位置执行操作  |
| `<C-d>`     | 向下翻半页并居中                       |
| `<C-u>`     | 向上翻半页并居中                       |
| `n`         | 下一个匹配并居中                       |
| `N`         | 上一个匹配并居中                       |

### 编辑操作

| 快捷键         | 功能                                                       |
| -------------- | ---------------------------------------------------------- |
| `J` (可视模式) | 下移选中行                                                 |
| `K` (可视模式) | 上移选中行                                                 |
| `sa`           | mini.surround — 添加环绕符号 (`sa(m` → 添加 `()` 包裹)     |
| `sd`           | mini.surround — 删除环绕符号 (`sd(` → 删除 `()`)           |
| `sr`           | mini.surround — 替换环绕符号 (`sr(['` → 替换 `()` 为 `''`) |
| `<leader>gf`   | 格式化文件 (conform.nvim)                                  |
| `u`            | 撤销                                                       |
| `<C-r>`        | 重做                                                       |
| `<leader>u`    | 打开撤销树                                                 |

---

## 快捷键大全

### `<leader>` 前缀 (`<space>`)

| 快捷键             | 功能                 | 插件      |
| ------------------ | -------------------- | --------- |
| `<space>ff`        | 查找文件             | Telescope |
| `<space>fg`        | 搜索文本 (live_grep) | Telescope |
| `<space>fb`        | 切换缓冲区           | Telescope |
| `<space>fh`        | 查找帮助             | Telescope |
| `<space>fd`        | 查看诊断列表         | Telescope |
| `<space>e`         | 切换文件树           | Neo-tree  |
| `<space>xx`        | 切换诊断面板         | Trouble   |
| `<space>xX`        | 当前文件诊断         | Trouble   |
| `<space>cs`        | 符号列表             | Trouble   |
| `<space>w`         | 保存文件             | 内置      |
| `<space>q`         | 退出                 | 内置      |
| `<space>u`         | 切换撤销树           | Undotree  |
| `<space>gf`        | 格式化               | Conform   |
| `<space>r`         | Flash 远程操作       | Flash     |
| `<C-^>` (插入模式) | 切换 Rime 中/英输入  | Rime      |
| `<C-@>` (插入模式) | 启用 Rime            | Rime      |
| `<C-_>` (插入模式) | 禁用 Rime            | Rime      |

### LSP 快捷键

| 快捷键      | 功能                   |
| ----------- | ---------------------- |
| `gd`        | 跳转到定义             |
| `gD`        | 查看引用               |
| `gt`        | 跳转到类型定义         |
| `gi`        | 跳转到实现             |
| `K`         | 悬停显示文档           |
| `<space>rn` | 重命名符号             |
| `<space>ca` | 代码操作 (code action) |
| `[d`        | 上一个诊断             |
| `]d`        | 下一个诊断             |

### 补全快捷键 (插入模式)

| 快捷键           | 功能             |
| ---------------- | ---------------- |
| `<C-n>`          | 选择下一个补全项 |
| `<C-p>`          | 选择上一个补全项 |
| `<C-b>`          | 向后滚动文档     |
| `<C-f>`          | 向前滚动文档     |
| `<C-e>`          | 取消补全         |
| `<CR>` / `<Tab>` | 确认补全         |

---

## 插件功能

| 插件                  | 功能                                   | 配置文件            |
| --------------------- | -------------------------------------- | ------------------- |
| **LSP**               | 语言服务协议支持（补全、诊断、跳转等） | `languages.nix`     |
| **cmp**               | 自动补全引擎                           | `plugins.nix`       |
| **luasnip**           | 代码片段引擎                           | `plugins.nix`       |
| **friendly-snippets** | 预置代码片段                           | `plugins.nix`       |
| **Treesitter**        | 语法高亮 + 代码缩进                    | `languages.nix`     |
| **Telescope**         | 模糊查找（文件、文本、缓冲区等）       | `plugins.nix`       |
| **Neo-tree**          | 文件树浏览器                           | `plugins.nix`       |
| **Lualine**           | 状态栏                                 | `plugins.nix`       |
| **Which-key**         | 快捷键提示弹窗                         | `plugins.nix`       |
| **Gitsigns**          | Git 变更标记（行内 blame、diff 标记）  | `plugins.nix`       |
| **Conform**           | 自动格式化                             | `languages.nix`     |
| **Flash**             | 快速跳转定位                           | `plugins.nix`       |
| **mini.surround**     | 成对符号包裹/删除/替换                 | `plugins.nix`       |
| **Fidget**            | LSP 进度提示                           | `plugins.nix`       |
| **Auto-session**      | 自动保存/恢复会话                      | `plugins.nix`       |
| **Undotree**          | 可视化撤销树                           | `plugins.nix`       |
| **Comment**           | 快速注释                               | `plugins.nix`       |
| **Todo-comments**     | TODO/FIXME 高亮                        | `plugins.nix`       |
| **Trouble**           | 诊断/符号列表面板                      | `plugins.nix`       |
| **Aerial**            | 代码大纲                               | `plugins.nix`       |
| **Noice**             | 通知/命令行美化                        | `plugins.nix`       |
| **Toggleterm**        | 浮动终端                               | `plugins.nix`       |
| **Rime**              | 中文字词输入法 (rime.nvim)             | `rime.nix`          |

---

## LSP 配置

当前启用的 LSP 服务器：

| 服务器          | 语言                    |
| --------------- | ----------------------- |
| `nixd`          | Nix                     |
| `lua_ls`        | Lua                     |
| `rust_analyzer` | Rust                    |
| `pyright`       | Python                  |
| `gopls`         | Go                      |
| `ts_ls`         | TypeScript / JavaScript |
| `bashls`        | Bash                    |
| `jsonls`        | JSON                    |
| `yamlls`        | YAML                    |
| `marksman`      | Markdown                |
| `typos_lsp`     | 拼写检查                |

如需添加新的 LSP 服务器，编辑 `modules/desktop/dev/nixvim/languages.nix` 中的 `vim.lsp.servers`。

---

## Rime 输入法

`rime.nvim` 在 Neovim 中集成了 [Rime](https://rime.im) 输入法引擎，无需系统输入法即可在 Neovim 中直接输入中文。

### 快捷键 (插入模式)

| 快捷键  | 功能              |
| ------- | ----------------- |
| `<C-^>` | 切换中/英输入模式 |
| `<C-@>` | 强制启用 Rime     |
| `<C-_>` | 强制禁用 Rime     |

### 使用提示

- 首次使用会自动加载系统已有的 Rime 配置（`~/.config/fcitx/rime/` 或 `~/.config/ibus/rime/`）
- 如果没有现成配置，需创建 `~/.config/rime/default.yaml`
- 输入方案在 `default.yaml` 中配置（拼音、五笔、双拼等）

### 注意事项

- `rime.nvim` 包含原生 C 扩展（通过 xmake 构建），首次构建需要 librime 和 luajit
- 如果构建失败，先尝试 `nix shell nixpkgs#librime` 确认库可用

---

## 配置结构

```
modules/desktop/dev/nixvim/
├── default.nix        # 入口，导入所有子模块
├── core.nix           # 核心设置：enable、globals、options、theme、autocmds
├── keymaps.nix        # 所有快捷键绑定
├── languages.nix      # LSP 服务器 + Treesitter + 格式化器配置
├── plugins.nix        # 所有插件配置（cmp、telescope、lualine、gitsigns 等）
├── rime.nix           # Rime 输入法自定义插件
└── neovide.nix        # Neovide GUI 配置
```

### 如何添加新插件

如果 Nixvim 已内置该插件的模块支持，直接在 `plugins.nix` 中添加对应的 `enable = true` 配置即可。

如果插件不在 Nixvim 内置模块中，使用 `vim.extraPlugins`：

```nix
{
  programs.nixvim.extraPlugins."my-plugin" = {
    package = pkgs.vimPlugins.my-plugin;
    setup = "require('my-plugin').setup {}";
  };
}
```

### 如何添加新快捷键

在 `keymaps.nix` 的 `programs.nixvim.keymaps` 列表中添加：

```nix
{
  mode = "n";
  key = "<leader>xx";
  action = "<cmd>SomeCommand<CR>";
  desc = "描述";
}
```

---

## Neovide 指南

### 启动

```bash
neovide .           # 在当前目录打开
neovide file.txt    # 打开文件
neovide --maximized # 最大化启动
```

### Neovide 特性

- 窗口圆角 (`corner_radius = 12`)
- 透明模糊效果 (`transparency = 0.92`, `blur = true`)
- 窗口动画 (`animated_windows = true`)
- 粒子光标效果 (`cursor_vfx_mode = "pixiedust"`)

---

## 常见问题

### Q: 修改配置后如何生效？

```bash
# 构建并切换
nixos-rebuild switch --flake .#nixos-desktop

# 或者仅测试
nix build .#homeConfigurations."rhencloud@nixos-desktop".activationPackage
```

### Q: 字体怎么修改？

编辑 `modules/desktop/dev/nixvim/neovide.nix` 中的 `font` 配置，以及系统的字体配置。

### Q: 某些 LSP 服务器没生效？

检查 `languages.nix` 中是否启用了对应语言的模块。部分语言需要额外安装包。

### Q: 格式化不工作？

`languages.nix` 中使用 `conform-nvim` 配置了 `format_on_save` 自动保存时格式化。手动格式化按 `<leader>gf`。确保对应语言的 formatter 已安装。

### Q: 会话恢复出问题？

`plugins.nix` 中的 `auto-session` 启用了自动保存/恢复。如果不需要某个目录的会话恢复，可以修改 `suppressed_dirs` 配置。
