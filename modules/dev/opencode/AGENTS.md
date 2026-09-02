# AGENTS.md — RhenCloud 全局配置

## 用户信息

- **用户名**: RhenCloud (rhencloud)
- **邮箱**: i@rhen.cloud
- **GitHub**: [@RhenCloud](https://github.com/RhenCloud)
- **GPG 密钥**: `REDACTED-59acd1c2`
- **时区**: Asia/Shanghai (UTC+8)

## 全局偏好

- **语言**: 代码注释和用户交互字符串使用**中文（简体）**
- **主题**: Dracula（starship 使用 Dracula 调色板，Stylix 系统级主题）
- **Shell**: 主 shell 为 fish
- **代码风格**: 简洁，**不添加注释**，不输出不必要的解释，保持回复在 4 行以内
- **表情符号**: **不使用**，除非用户明确要求

## 工具/依赖管理原则

- **优先使用 Nix 管理依赖和工具**：能用 Nix Flakes / nix shell 解决的问题，优先使用 Nix，而非传统包管理器（npm/pip/cargo install 等）
- 项目内开发依赖通过 `shells/` 下的 devShell 或 flake 中的 `devShells` 声明
- 全局工具通过 Home Manager 的 `home.packages` 安装
- 仅在以下情况回退到非 Nix 方案：
  - 工具没有 nixpkgs 包且无法自行打包
  - 需要特定版本管理（如 nvm/fnm 管理 Node.js 版本）
  - 临时/一次性的工具安装

## 全局开发环境

- **系统**: NixOS（nixos-unstable 频道）
- **包管理**: Nix Flakes + Snowveil
- **运行时**: Bun 1.3.x、Node.js、Deno、Rust、Go、Python、Java、Kotlin
- **编辑器**: VS Code、Neovim（通过 Nixvim 配置）
- **终端**: Kitty（主）、Ghostty
- **窗口管理器**: Hyprland + Niri
- **Shell 提示符**: Starship（Dracula 主题）

## Git 约定

```
[user]
  name = RhenCloud
  email = i@rhen.cloud
  signingkey = REDACTED-59acd1c2
[init]
  defaultBranch = main
[commit]
  gpgsign = true
[tag]
  gpgsign = true
```

- **所有提交必须 GPG 签名**
- 提交信息使用英文，简洁准确
- diff 工具: `kitten diff`
- bun.lock 文件: 视为二进制文件，使用 `bun` 作为 textconv
- GPG 程序: `/etc/profiles/per-user/rhencloud/bin/gpg`

## Nix 约定

- **频道**: nixos-unstable
- **stateVersion**: 26.11
- **允许不自由软件**: `allowUnfree = true`
- **不自由包白名单**: `electron-39.8.10`（QQ 相关包所需）
- **硬件配置**: `hardware-configuration.nix` **不要手动编辑**，通过 `nixos-generate-config` 生成
- **格式化工具**: `nixfmt`
- **回滚**: `sudo nixos-rebuild switch --rollback`

### 缓存镜像

| 源              | URL                                      |
| --------------- | ---------------------------------------- |
| 上游            | `cache.nixos.org`                        |
| 中科大          | `mirrors.ustc.edu.cn/nix-channels/store` |
| 上交大          | `mirror.sjtu.edu.cn/nix-channels/store`  |
| Hyprland Cachix | `hyprland.cachix.org`                    |
| Niri Cachix     | `niri.cachix.org`                        |
| Noctalia Cachix | `noctalia.cachix.org`                    |
| Vicinae Cachix  | `vicinae.cachix.org`                     |

## SSH 配置

- **密钥**: `~/.ssh/id_ed25519`
- **SSH 代理**: 使用 GPG SSH agent（`~/.gnupg/S.gpg-agent.ssh`）
- **SSH 配置**: `~/.ssh/config` 中设置了 `identityAgent` 指向 GPG agent

## opencode 配置

位置: `~/.config/opencode/`

### MCP 服务器

| 名称     | 类型   | 用途                                      |
| -------- | ------ | ----------------------------------------- |
| `github` | remote | GitHub API 集成（Copilot MCP）            |
| `nixos`  | local  | NixOS 选项/包查询（通过 `uvx mcp-nixos`） |

### 提供者

| 名称         | 端点                                   |
| ------------ | -------------------------------------- |
| `me`         | `http://127.0.0.1:8080/v1`（本地模型） |
| `voidswitch` | `https://voidswitch.siiway.org/v1`     |
| `sub2api`    | `https://sub2api.wss.moe`              |
| `kimi`       | `https://api.0x7e.vip/v1`              |

### 已安装技能

- `code-review-skill/` — 代码审查
- `frontend-design/` — 前端设计
- `herdr/` — herdr 标签重命名

## 全局行为约定

- **不要**生成或猜测 URL，除非你确定它们能帮助用户
- **不要**使用 `sed`、`awk`、`echo >`、`cat <<EOF` 来修改文件 — 使用 Write/Edit 工具
- **不要**在文件修改后添加代码解释或总结，除非用户要求
- **不要**主动提交（commit/push），除非用户明确要求
- **先理解**现有代码约定（导入、框架选择、命名、类型），再编写新代码
- **外部临时目录**使用 `/tmp/opencode`
- **完成修改后**运行 lint/typecheck（如果可用）
- **敏感信息**通过 sops 加密存储在仓库 `secrets/` 目录下（`common.yaml` + `hosts/<host>.yaml`）

## 常见项目模式

### NixOS 配置项目（~/nixos）
- 构建并切换: `sudo nixos-rebuild switch --flake .#nixos-desktop`
- 仅构建: `nixos-rebuild build --flake .#nixos-desktop`
- 测试: `sudo nixos-rebuild test --flake .#nixos-desktop`
- 查差异: `nix diff-closures /run/current-system result`
- 更新所有输入: `nix flake update`
- 更新单个: `nix flake update <input-name>`
- 清理: `sudo nix-collect-garbage -d`
- 进入 Python devShell: `nix develop .#python`

### 添加新模块
- **Home Manager**: 创建 `modules/<scope>/<name>/home.nix`，Snowveil 自动发现
- **NixOS**: 创建 `modules/<scope>/<name>/nixos.nix`，Snowveil 自动发现

### 管理密钥
```bash
sops secrets/common.yaml                    # GPG 管理员密钥解密编辑
sops secrets/hosts/nixos-desktop.yaml
# 保存后 sops 自动重新加密；然后声明到模块中 sops.secrets."<name>"，提交即可
```
