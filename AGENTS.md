# AGENTS.md

RhenCloud 的 NixOS 系统配置，基于 **flake-parts** 以 Nix flake 方式管理。

## 仓库结构

```
flake.nix                      # 入口点：inputs、flake-parts 配置、子模块导入
flake/pkgs.nix                 # perSystem pkgs（allowUnfree + overlays）
flake/nixos.nix                # NixOS 配置（自动发现 systems/<arch>/<host>/）
flake/home-manager.nix         # Home Manager 配置（自动发现 homes/<arch>/<user>@<host>/）
flake/packages.nix             # 自定义包（herdr-tab-rename、aicommits、deploy-rs 等）
flake/devshells.nix            # devShells（default + python）+ formatter（nixfmt）
flake/checks.nix               # flake checks（formatting/statix/deadnix/eval/secrets）
flake/deploy.nix               # deploy-rs 节点定义
flake/helpers.nix              # 内部辅助（overlay 发现、home 模块分组、collectDefaultNix）
systems/x86_64-linux/{nixos-desktop,yc-hk-1,arch-server}/
                               # 每主机入口（default.nix + hardware-configuration.nix）
homes/x86_64-linux/{rhencloud@nixos-desktop,rhencloud@yc-hk-1,rhencloud@arch-server,wyf9@yc-hk-1}/
                               # 每用户每主机的 Home Manager 入口
modules/nixos/{core,desktop,service}/  # 系统级模块（collectDefaultNix 自动收集）
modules/home/{core,desktop,dev,service}/  # Home Manager 模块（自动收集）
modules/options.nix            # 全局选项（my.*，如 my.user / my.host / my.stateVersion）
secrets/                       # sops 加密的密钥（common.yaml + hosts/<host>.yaml）
overlays/                      # 自定义包 overlay（niri、portal-gtk、mexkey3-ccid、go-musicfox 等）
packages/                      # 自定义包（packages.nix 的 discoverPackages 自动发现）
patches/                       # niri 的补丁
```

## 架构说明

- **框架**：flake-parts 取代 Snowfall Lib。
- **主机**：`nixos-desktop`（桌面）、`yc-hk-1`（服务器）、`arch-server`（未使用）。主机名在 `systems/<arch>/<host>/default.nix` 中设置。
- **主用户**：`rhencloud`，选项定义于 `modules/options.nix`（`my.*`）。NixOS 配置通过 `flake/nixos.nix` 的 `specialArgs`（`{ inherit inputs; }`）与 HM 的 `extraSpecialArgs`（`primaryUser`）传入。
- **频道**：`nixos-unstable`（另有 `nixpkgs-stable` = 25.11 输入）。
- **stateVersion**：`26.11`。
- **窗口管理器**：Hyprland 和 Niri 均已配置。
- **密钥**：由 [sops-nix](https://github.com/Mic92/sops-nix) 管理。加密文件位于 `secrets/`。加密密钥：GPG 管理子密钥 `CE243917D8877F3AFE5814335850468557847C77`（编辑）+ 每主机 SSH host key → age（运行时解密）。每主机配置 `sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]`。
- **模块中的密钥**：使用 `config.sops.secrets."<name>".path`（运行时解密到 `/run/secrets/<name>`）和 `sops.templates`（占位符 `${config.sops.placeholder."<key>"}` 在 activation 时渲染）。**绝不**使用 `builtins.readFile` 读取密钥。
- **HM 密钥**：NixOS 层通过 `sops.templates`（`/run/secrets/templates/`）渲染完整配置文件；HM 用 `config.lib.file.mkOutOfStoreSymlink "/run/secrets/templates/<file>"` 引用。
- **主题**：Stylix 提供系统级主题（Dracula）。
- **Overlays**：定义于 `overlays/<name>/default.nix`，在 NixOS（`flake/nixos.nix`）与 home-manager（`flake/helpers.nix` 的 `essentialHomeModules`）中均通过 `nixpkgs.overlays` 应用。
- **模块自动发现**：`flake/helpers.nix` 的 `collectDefaultNix` 递归遍历 `modules/nixos` 与 `modules/home` 收集所有 `default.nix`（含 `disabled` 标记跳过）。Snowfall 风格的 `rhencloud.*` 选项是普通 NixOS 模块选项，而非命名空间魔法。
- **主机/home 自动发现**：`flake/nixos.nix` 扫描 `systems/<arch>/`，`flake/home-manager.nix` 扫描 `homes/<arch>/`，无需手动注册。
- **checks**：`flake/checks.nix` 定义 formatting/statix/deadnix/eval/secrets 检查，由 `nix flake check` 统一执行。

## 常用命令

```bash
# 仅构建（创建 ./result 符号链接）
nixos-rebuild build --flake .#nixos-desktop

# 测试但不创建引导项
sudo nixos-rebuild test --flake .#nixos-desktop

# 对比当前与新建闭包的包差异
nix diff-closures /run/current-system result

# 回滚到上一个 generation
sudo nixos-rebuild switch --rollback

# 更新所有 flake inputs
nix flake update

# 清理旧 generation 并回收磁盘空间
sudo nix-collect-garbage -d

# 进入 Python dev shell
nix develop .#python

# 统一质量检查（formatting + statix + deadnix + eval + secrets）
nix flake check --all-systems
```

## 注意事项

- 部分模块在其父级 `default.nix` 中被注释掉（例如 `modules/nixos/core/` 和 `modules/nixos/desktop/` 中的 `./proxy.nix`）。在假定某模块生效前先检查父级 `default.nix`。
- `home-manager.backupFileExtension = "backup"` — HM 会将冲突文件备份为 `.backup` 后缀。
- `flake.nix` 的 `nixConfig.substituters` 配置了中国镜像（USTC、SJTU）与上游缓存。rhencloud/hyprland/noctalia/niri 等 Cachix 缓存已启用。
- `permittedInsecurePackages` 包含 `electron-39.8.10` 等 — QQ 相关包所需。
- `hardware-configuration.nix` **不要**手动编辑；用 `nixos-generate-config` 重新生成。
- 路径名中的 `@`（如 `rhencloud@nixos-desktop`）是合法 Nix 语法，但可能触发 LSP 误报。
- `format-lint.yml` 使用 `nixfmt-rfc-style`，与 `formatter`（nixfmt）同一工具。

## 常见修改模式

**新增 Home Manager 模块**：创建 `modules/home/<category>/<name>/default.nix`。`collectDefaultNix` 自动包含。

**新增 NixOS 模块**：创建 `modules/nixos/<category>/<name>/default.nix`。同样自动包含。

**新增主机**：1) 创建 `systems/x86_64-linux/<hostname>/default.nix` + `hardware-configuration.nix`。2) 创建对应的 `homes/x86_64-linux/<user>@<hostname>/default.nix`。两者由 `flake/nixos.nix` 和 `flake/home-manager.nix` 自动发现。

**新增 flake input**：添加到 `flake.nix` 的 `inputs`。若提供 NixOS 模块，加入 `flake/nixos.nix` 的 `modules` 列表；若提供 Home Manager 模块，加入 `flake/helpers.nix` 的 `essentialHomeModules` / `desktopExtraHomeModules`。

**更新单个 flake input**：`nix flake update <input-name>`（如 `nix flake update home-manager`）。

## 密钥工作流

```bash
# 编辑加密文件（GPG 管理密钥解密；保存时重新加密）
sops secrets/common.yaml
sops secrets/hosts/nixos-desktop.yaml

# 新增密钥：编辑文件后，在模块中声明
sops.secrets."my-key" = { sopsFile = ./secrets/hosts/nixos-desktop.yaml; owner = "root"; mode = "0400"; };

# 新增主机：将其 SSH host 公钥转为 age，添加到 .sops.yaml，重新加密
ssh-keyscan <host> | nix shell nixpkgs#ssh-to-age -c ssh-to-age
sops updatekeys secrets/common.yaml
sops updatekeys secrets/hosts/<host>.yaml
```

## 风格

- 代码注释与面向用户的字符串使用**中文（简体）**。
- Nix 格式化工具：`nixfmt`（= nixfmt-rfc-style，在 `home.packages` 与 `formatter` 中）。
- 静态检查：`statix check .`（配置见 `statix.toml`）。
- Secrets 扫描：`gitleaks`（配置见 `.gitleaks.toml`，排除 `secrets/` 加密目录）。
