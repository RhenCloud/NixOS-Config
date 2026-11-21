# Neovim（nixvim）使用指南

本仓库通过 **nixvim** 声明式管理 Neovim，配置位于 `modules/dev/nixvim/`，仅对启用
`rhencloud.nixvim.enable` 的用户/主机生效（当前：`rhencloud@nixos-desktop` 的 dev 角色）。

- 配色：**Dracula**（brgt/dracula-nvim，状态栏 lualine 同步）
- 文件浏览：**Oil**（_bufferline 风格未启用，Oil 即默认资源管理器_）
- 补全：**nvim-cmp + LuaSnip**（friendly-snippets VSCode 合集）
- LSP：9 个 server 全部显式绑定 nixpkgs store 包，无运行时自动下载
- 中文输入：**rime.nvim**（编辑器内 Rime，配合系统 fcitx5 双保险）

按键约定：`<leader>` = **空格**，`<localleader>` = **`\`**。

---

## 目录

- [文件与编辑](#文件与编辑)
- [补全与 snippet](#补全与-snippet)
- [LSP 与诊断](#lsp-与诊断)
- [格式化与 lint](#格式化与-lint)
- [Telescope 搜索](#telescope-搜索)
- [Git（gitsigns）](#gitgitsigns)
- [Buffer 与窗口](#buffer-与窗口)
- [终端（toggleterm）](#终端toggleterm)
- [窗口内搜索（flash）](#窗口内搜索flash)
- [中文输入（rime）](#中文输入rime)
- [其他内置能力](#其他内置能力)
- [语言支持矩阵](#语言支持矩阵)
- [配置结构](#配置结构)
- [常见问题](#常见问题)

---

## 文件与编辑

| 快捷键        | 功能                                      |
| ------------- | ----------------------------------------- |
| `<leader>e`   | 打开/进入 Oil 文件浏览（同目录树）        |
| `<leader>w`   | 保存（`:write`）                          |
| `<leader>q`   | 退出当前窗口/缓冲区（`:quit`）            |
| `<leader>cf`  | 用 conform 格式化当前缓冲（无 LSP 时兜底）|
| `<C-d>`/`<C-u>` | 半页滚动并居中（`zz`）                  |

选择框（内置 `input()`/`select()`，如 `<Tab> 补全菜单确认外的原生命令选择）由
**dressing.nvim** 美化，浮动窗口 + 编号列表。

## 补全与 snippet

触发：插入模式下正常输入即弹 cmp 菜单。

| 快捷键             | 功能                                                    |
| ------------------ | ------------------------------------------------------- |
| `<C-p>` / `<C-n>`  | 补全菜单 上 / 下                                        |
| `<C-b>` / `<C-f>`  | 补全菜单 翻页                                           |
| `<CR>`             | 确认选中项（默认首选时直接回车）                        |
| `<C-e>`            | 关闭菜单、原样输入                                      |
| `<Tab>`            | 展开 snippet；snippet 内**跳到下一个占位**；否则插入制表符 |
| `<S-Tab>`          | snippet 内**跳回上一个占位**                            |
| `<C-Space>`        | 手动触发补全                                            |
| `<C-x><C-o>`       | 触发 LSP completion                                     |
| `<C-x><C-u>`       | 触发 luasnip 源补全                                     |

snippet 来源：friendly-snippets（全局 + 各语言）+ 你自定义的
`~/.local/share/nvim/luasnip/`（若有）。插入 LSP `snippet` 类型补全项时使用与 LuaSnip
相同的 Tab/S-Tab 跳转。

## LSP 与诊断

已启用的 server（全部 nixpkgs 包直绑）：

| Server          | 语言                       | 备注                                   |
| --------------- | -------------------------- | -------------------------------------- |
| `lua_ls`        | Lua                        | 已声明 `vim` 全局，禁三方检查/遥测     |
| `nixd`          | Nix                        | 格式化走 nixfmt                        |
| `bashls`        | Shell                      |                                        |
| `pyright`       | Python                     | 类型检查关闭（lint 交给 ruff）         |
| `ts_ls`         | JS / TS                    |                                        |
| `rust_analyzer` | Rust                       | `check = clippy`；工具链由 rustup 提供 |
| `clangd`        | C / C++                    | 来自 clang-tools                       |
| `gopls`         | Go                         | staticcheck + 自动补 import            |
| `jdtls`         | Java                       |                                        |
| `typos_lsp`     | 几乎所有文本文件           | 拼写检查（Hint 级）                    |

缓冲区内按键（仅 LSP 生效时可用）：

| 快捷键           | 功能                 |
| ---------------- | -------------------- |
| `gd`             | 跳转定义             |
| `gD`             | 查看引用             |
| `gt`             | 跳转类型定义         |
| `gi`             | 跳转实现             |
| `K`              | 悬浮文档（hover）    |
| `<leader>rn`     | 重命名符号           |
| `<leader>ca`     | 代码操作（code action）|
| `]d` / `[d`      | 下一 / 上一诊断      |
| `<leader>dn`     | **neogen**：为光标处函数/类生成文档注释（非 silent，可修改）|

诊断呈现：lsp-lines 在行内聚合显示诊断；Trouble（见下）汇总列表。

## 格式化与 lint

**conform.nvim**：保存自动格式化（`format_on_save`，LSP 优先、formatter 兜底，超时 1s）。

| 类型     | 格式化工具（store 直绑）                |
| -------- | --------------------------------------- |
| Nix      | nixfmt                                  |
| Lua      | stylua                                  |
| Python   | isort → black                           |
| Rust     | rustfmt（rustup 工具链）                |
| Go       | gofmt（go 工具链）                      |
| JS/TS/JSON/YAML/MD/HTML/CSS | prettierd        |
| 其他     | trim_whitespace                         |

手动格式化：`<leader>cf`。

**nvim-lint**：保存时触发 lint（非诊断刷屏，与 LSP 诊断互补）：

| 类型        | linter |
| ----------- | ------ |
| Python      | ruff   |
| JavaScript  | eslint |
| TypeScript  | eslint |

## Telescope 搜索

| 快捷键          | 功能                   |
| --------------- | ---------------------- |
| `<leader>ff`    | 文件查找（fzf 预览）   |
| `<leader>fg`    | live_grep 全文搜索     |
| `<leader>fb`    | buffer 列表            |
| `<leader>fh`    | 帮助搜索              |
| `<leader>fd`    | 诊断列表              |

依赖 ripgrep/fd 由 home 环境提供，已在 PATH。

## Git（gitsigns）

| 快捷键           | 功能                         |
| ---------------- | ---------------------------- |
| `]h` / `[h`      | 下 / 上一个 git 改动块       |
| `<leader>gs`     | 暂存 hunk                    |
| `<leader>gS`     | 暂存整个 buffer              |
| `<leader>gu`     | 撤销暂存                     |
| `<leader>gb`     | 对当前行 blame（虚文本）     |
| `<leader>gd`     | diff 当前文件                |
| `<leader>gD`     | 显示/隐藏删除行              |
| `<leader>gp`     | 预览 hunk                    |

## Buffer 与窗口

| 快捷键           | 功能                         |
| ---------------- | ---------------------------- |
| `<Tab>`          | 下一个 buffer                |
| `<S-Tab>`        | 上一个 buffer                |
| `<leader>bb`     | mini.pick 的 buffer 选择器   |
| `<leader>bd`     | 关闭当前 buffer（`:bdelete`）|
| `<C-h/j/k/l>`    | 左/下/上/右 切换窗口         |
| `<C-↑/↓/←/→>`    | 调整窗口高宽                 |
| `<leader>ww`     | 聚焦还原窗口（`<C-w>=` 等宽）|
| `<leader>wv`     | 垂直分屏（`:vsplit`）        |
| `<leader>ws`     | 水平分屏（`:split`）         |
| `<leader>wh/wl`  | 向左/右横滚（`zH`/`zL`）     |

`scrolloff=8`、`sidescrolloff=8`、`mouse=a` 已启用。mini.tabline 在顶部提供无原生
tabline 的迷你标签条。

## 终端（toggleterm）

| 快捷键            | 功能                       |
| ----------------- | -------------------------- |
| `<leader>tt`      | 浮动终端（带圆角边框）     |
| `<leader>th`      | 水平分屏终端               |
| `<leader>tv`      | 垂直分屏终端               |
| `<Esc><Esc>`      | 终端（t 模式）内关闭当前终端窗口 |

- 终端打开自动进入插入模式（TermOpen → startinsert）。
- 进程退出后 buffer 自动 `bwipeout!`（TermClose autocmd），不留僵尸缓冲。

## 窗口内搜索（flash）

| 快捷键       | 功能                             |
| ------------ | -------------------------------- |
| `s` / `S`    | 两字符跳（当前窗口，大小写敏感） |
| `<leader>r`  | 全窗口树范围搜索跳转             |

普通 `/`、`?` 搜索后 `n` / `N` 自动居中（`zzzv`，`nowait` 不阻塞 flash 抢键）。

## 中文输入（rime）

编辑器内嵌 **rime.nvim**（默认沿用 `~/.local/share/fcitx5/rime`，与系统 fcitx5
共用同一套 CloudKeyTao 词库），与系统 fcitx5 并行：

| 快捷键（插入模式）    | 功能                         |
| --------------------- | ---------------------------- |
| `<C-^>`（Ctrl+`）     | 中英文方案切换               |
| `<C-@>`               | 启用 rime                    |
| `<C-_>`               | 禁用 rime                    |

若与系统输入法冲突，以你当时聚焦的前端为准（GUI 内 rime，终端里走 fcitx5）。

## 其他内置能力

- **auto-session**：目录级会话自动保存/恢复（`/`、`/tmp`、`/etc` 不启用）。
- **which-key**：leader 按住即显示键位提示（`delay=0` 即时弹出）。分组：
  `<leader>f` 查找 / `c` 代码 / `g` Git / `w` 窗口 / `x` 诊断 / `e` Oil / `t` 终端 / `b` Buffer / `d` 文档，另有 `<localleader>`（语言）组。
- **mini.surround**：`sa`/`sd`/`sr` 增删换引号标签。
- **dial.nvim**：`<A-a>` / `<A-x>` 对数字/布尔/十六进制等 +1 / -1（visual 模式对多行递增）。
- **indent-blankline + treesitter-context**：缩进参考线 + 顶部上下文钉住；`\c`（localleader）开关上下文钉住。
- **todo-comments**：TODO/FIXME/NOTE 高亮开启（默认关键词），未绑定列表键位，可用
  `:TodoTrouble` / `:TodoQuickFix` 手动调出（trouble/telescope 已在环境内）。
- **fidget / notify**：LSP 进度与通知（notify 默认级别 warn）。
- **render-markdown**：Markdown 标题/列表/代码块原地渲染。
- ** autopairs**：括号自动配对。
- **colorizer**：CSS 颜色值染色。

## 语言支持矩阵

| 语言     | LSP          | 格式化        | lint   | 工具链来源（dev.* 模块）          |
| -------- | ------------ | ------------- | ------ | --------------------------------- |
| Nix      | nixd         | nixfmt        | —      | nixpkgs（含 Zed 用的 nil 保留）   |
| Lua      | lua_ls       | stylua        | —      | home 包                           |
| Python   | pyright      | isort+black   | ruff   | python315 + uv + ruff             |
| Rust     | rust_analyzer| rustfmt       | —      | rustup（clippy 组件）             |
| Go       | gopls        | gofmt         | —      | go + gopls                        |
| C/C++    | clangd       | —             | —      | clang/llvm                        |
| JS/TS    | ts_ls        | prettierd     | eslint | nodejs_latest + pnpm/bun          |
| Java     | jdtls        | —             | —      | zulu17 + jdt-language-server      |
| Shell    | bashls       | —             | —      | bash-language-server              |
| 文本     | typos_lsp    | —             | 拼写   | 所有上述文件类型                  |

## 配置结构

```
modules/dev/nixvim/
├── home.nix       # 模块入口：rhencloud.nixvim.enable 开关 + 引入以下文件
├── core.nix       # leader、选项、autocmd（yank 高亮 / TermClose 清理 / VimResized）
├── keymaps.nix    # 全部普通键位（唯一事实源）
├── plugins.nix    # 通用插件 + which-key 分组 + luasnip/cmp/telescope/...
├── languages.nix  # treesitter、LSP servers+settings、conform、lint、typos_lsp
├── rime.nix       # rime.nvim 与 Rime 数据目录（手搓 derivation，升级时最易碎）
└── neovide.nix    # Neovide GUI 设置（字体 Maple Mono NF CN 等）
```

改完用 `nix build .#homeConfigurations.rhencloud@nixos-desktop.activationPackage`
+ `nix flake check` 验证，再自行 switch。

## 常见问题

**Q：`<leader>e` 和过去的 Neo-tree 去哪了？**
A：Neo-tree 已移除，`<leader>e` 现在打开的是 Oil（buffer 里像编辑文件一样浏览/改名/删除，`:wq` 生效）。

**Q：按 `<Tab>` 没跳 snippet？**
A：Tab 逻辑优先级是「展开 snippet → 跳段 → 制表符」。只有光标处于可展开的 snippet
占位（`expand_or_locally_jumpable`）时才被 cmp 截获，普通行缩进输入 Tab 不受影响。

**Q：Java 的 `jdtls` 起不来 / 报找不到 JAVA_HOME？**
A：dev.java 已设 `JAVA_HOME=zulu17`，若终端里启动 nvim 前未加载该环境变量，先
`java17` 相关 profile 生效（重新登录 shell）再试。

**Q：编辑器内打字英文正常，中文不上屏？**
A：先按 `<C-^>` 切换 rime 方案；仍无则在系统层切 fcitx5。rime 与 fcitx5 二选一同时用即可，
GUI 程序（Neovide）走 rime，tty/终端走 fcitx5。

**Q：升级 nixpkgs / nixvim 后 nvim 挂了？**
A：按脆弱度顺序排查：`rime.nix`（手搓 xmake derivation，头号嫌疑）→ `languages.nix` 里
`uri_from_bufnr` 0.11 shim（新版 Neovim 已原生提供，可删）→ 插件 API 变动（cmp 映射、
mini.pick）。可先注释对应模块 build 验证再逐个恢复。

**Q：想临时用一个不带任何插件的 nvim？**
A：`nix run nixpkgs#neovim` 不会读取 nixvim 生成配置（其配置经 XDG_CONFIG_HOME 下
`nvim/` 链接），但要完全干净用 `nvim --clean`。
