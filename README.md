# RhenCloud 的 NixOS 配置

[![Mirror Repository](https://github.com/RhenCloud/NixOS-Config/actions/workflows/mirror.yml/badge.svg)](https://github.com/RhenCloud/NixOS-Config/actions/workflows/mirror.yml)
[![Build & Push to Cachix](https://github.com/RhenCloud/NixOS-Config/actions/workflows/build.yml/badge.svg)](https://github.com/RhenCloud/NixOS-Config/actions/workflows/build.yml)
[![Deploy](https://github.com/RhenCloud/NixOS-Config/actions/workflows/deploy.yml/badge.svg)](https://github.com/RhenCloud/NixOS-Config/actions/workflows/deploy.yml)

## 镜像仓库

本仓库同时托管于以下平台，内容保持同步：

| 平台 | 链接 |
| --- | --- |
| **GitHub** | https://github.com/RhenCloud/NixOS-Config |
| **GitLab** | https://gitlab.com/RhenCloud/NixOS-Config |
| **Codeberg** | https://codeberg.org/RhenCloud/NixOS-Config |
| **cnb.cool** | https://cnb.cool/RhenCloud/NixOS-Config |

## 介绍

| 项目 | 实现 |
| --- | --- |
| 启动器 / 顶栏 | [Noctalia Shell](https://noctalia.dev) |
| 终端 | [Kitty](https://github.com/kovidgoyal/kitty) |
| 编辑器 | VS Code / Neovim（Nixvim） |
| 字体 | [Maple Mono NF CN](https://github.com/subframe7536/Maple-font) |
| 主题 | [Dracula](https://draculatheme.com) |
| Shell | [Fish](https://fishshell.com) |
| 窗口管理器 | Hyprland / Niri / Mango |
| 输入法 | [Fcitx5](https://fcitx-im.org) · [Rime](https://rime.im) |
| 音乐播放 | [go-musicfox](https://github.com/go-musicfox/go-musicfox) |
| 截图工具 | [Flameshot](https://flameshot.org) |
| 剪贴板 | [Clipse](https://github.com/savedra1/clipse) |
| 壁纸管理器 | [Waypaper](https://github.com/anufrievroman/waypaper) |
| 桌面歌词 | [Waylyrics](https://github.com/waylyrics/waylyrics) |
| 浏览器 | [Zen Browser](https://zen-browser.app) |

## 架构

本仓库使用 [Cloud Nix Framework](https://github.com/RhenCloud/Cloud-Nix-Framework) 按目录约定生成 Nix flake 输出。`flake.nix` 负责声明 inputs，并通过：

```nix
inputs.cloud.lib.mkFlake {
  inherit inputs systems;
  nixpkgs.config.allowUnfree = true;
  outputs.extra = import ./flake/extra-outputs.nix { inherit inputs; };
}
```

生成主机、Home Manager、模块、包、overlay 及常用扩展输出。只有 ISO 这类暂未采用目录约定的输出保留在 `flake/extra-outputs.nix`。

```text
flake.nix
    │
    ├── Cloud Nix Framework
    │   ├── nixosConfigurations  ← hosts/<host>/
    │   ├── homeConfigurations   ← homes/<user>/<host>.nix
    │   ├── nixosModules         ← modules/**/{default,nixos}.nix
    │   ├── homeModules          ← modules/**/{default,home}.nix
    │   ├── packages             ← packages/<name>/default.nix
    │   ├── overlays             ← overlays/<name>/default.nix
    │   ├── apps                 ← apps/<name>/default.nix
    │   ├── checks               ← checks/<name>/default.nix
    │   ├── devShells            ← shells/<name>/default.nix
    │   ├── formatter            ← formatter/default.nix
    │   └── deploy               ← deploy/default.nix
    │
    └── flake/extra-outputs.nix  ← nixosConfigurations.iso
```

顶层目录职责：

```text
hosts/      NixOS 主机入口，目录名为 <host>，架构在 meta.nix 中声明
homes/      每用户、每主机的 Home Manager 入口
modules/    NixOS 与 Home Manager 共用的单树模块
packages/   自动发现的自定义包
overlays/   自动发现的 nixpkgs overlays
apps/       自动发现的 flake apps
checks/     自动发现的 flake checks
shells/     自动发现的开发环境
formatter/  flake formatter
deploy/     deploy-rs 节点配置
flake/      不符合目录约定的额外 flake outputs
secrets/    sops 加密密钥
patches/    本地补丁
```

分层关系仍为 `host → role → module`：

- 主机在 `hosts/<host>/meta.nix` 中声明 `system` 与 `roles = [ ... ]`，`default.nix` 只保留 NixOS 配置。
- `modules/desktop/`、`modules/server/` 只注入对应角色。
- `modules/_common/` 始终注入所有主机和 home。
- `modules/<role>/roles/nixos.nix` 定义并聚合 `rhencloud.roles.<role>` 所启用的能力。
- 主机入口只保留身份、硬件、网络、存储及该主机独有的服务开关。

## 主机

| 主机 | 类型 | 说明 |
| --- | --- | --- |
| `nixos-desktop` | 桌面 | 日常使用，Hyprland / Niri / Mango |
| `yc-hk-1` | 服务器 | deploy-rs 远程部署，运行容器化与自托管服务 |
| `nixos-homeserver` | 服务器 | 预留家庭服务器配置 |

## 目录发现约定

### 主机与 Home Manager

- `hosts/<host>/default.nix` → `nixosConfigurations.<host>`
- `homes/<user>/<host>.nix` → `homeConfigurations."<user>@<host>"`
- `homes/<user>/default.nix` 可作为该用户的共享 Home Manager 配置

例如：

```text
hosts/nixos-desktop/{meta.nix,default.nix}
homes/rhencloud/nixos-desktop.nix
```

### 模块单树

框架按 magic 文件名分拣模块：

- `default.nix`：NixOS 与 Home Manager 两侧都会加载，适合声明共享选项。
- `nixos.nix`：仅加载到 NixOS。
- `home.nix`：仅加载到 Home Manager。

模块目录可任意嵌套。非 magic 文件（例如 `mod.nix`）不会由框架直接发现，需要由相邻的 `home.nix` 或 `nixos.nix` 显式导入。

模块目录还可通过 `meta.nix` 声明 `requires`、`after`、`before`、`wants` 和 `conflicts`。本仓库已为读取 `config.my.*` 的模块以及 desktop/server 角色聚合器声明硬依赖，使主机级模块覆盖造成的缺失能在框架组合阶段直接报错。

### 约定式 outputs

- `packages/<name>/default.nix` → `packages.<system>.<name>`
- `overlays/<name>/default.nix` → `overlays.<name>`
- `apps/<name>/default.nix` → `apps.<system>.<name>`
- `checks/<name>/default.nix` → `checks.<system>.<name>`
- `shells/<name>/default.nix` → `devShells.<system>.<name>`
- `formatter/default.nix` → `formatter.<system>`
- `deploy/default.nix` → `deploy`

`flake.nix` 的 `nixpkgs.config` 统一配置 `allowUnfree`、`permittedInsecurePackages` 等选项。自动发现的 overlays 会统一应用于 NixOS、独立/嵌入式 Home Manager、packages、checks、devShells、apps 和 formatter。

## 构建 / 测试 / 部署

```bash
nix run .#build -- nixos-desktop        # 仅构建，不切换
nix run .#test -- nixos-desktop         # 测试但不创建引导项（需 root）
nix run .#switch -- nixos-desktop       # 构建并切换（需 root）
nix run .#deploy -- yc-hk-1             # deploy-rs 远程部署
```

等价原生命令：

```bash
nixos-rebuild build --flake .#nixos-desktop
sudo nixos-rebuild test --flake .#nixos-desktop
sudo nixos-rebuild switch --flake .#nixos-desktop
nix run .#deploy-rs -- ".#yc-hk-1" --auto-rollback true
```

独立构建 Home Manager：

```bash
nix build '.#homeConfigurations."rhencloud@nixos-desktop".activationPackage'
```

> 省略参数时，build/test/switch 默认使用 `nixos-desktop`，deploy 默认使用 `yc-hk-1`。

## 质量检查

```bash
nix flake check --all-systems
```

检查项包括 CNF discovery/expected 校验、nixfmt、statix、deadnix、gitleaks、桌面主机求值、`advan10` Home Manager 求值和 deploy-rs 节点结构。

## CI

| 工作流 | 触发 | 作用 |
| --- | --- | --- |
| `format-lint.yml` | PR / push main | nixfmt + statix + deadnix + gitleaks；PR 执行完整 flake 求值但不重复构建闭包 |
| `build.yml` | PR / push main | 使用 CNF 统一的主机 `pkgs` 构建主机、flake 包与 overlay 包，推送 Cachix |
| `build-home-manager.yml` | push main | 自动发现并构建全部 Home Manager activation packages，归档桌面 generation |
| `build-rime.yml` | push main | 构建 Rime 配置与 Fcitx5 主题 |
| `deploy.yml` | build.yml 成功后 | 先校验 `deploy.nodes`，再通过自动发现的 `apps.deploy` 部署 `yc-hk-1` |
| `update-flake-lock.yml` | 定时 | 自动更新 `flake.lock` |
| `mirror.yml` | push main | 同步镜像仓库 |

## 管理 Secrets

本仓库使用 [sops-nix](https://github.com/Mic92/sops-nix) 管理 `secrets/` 下的敏感数据。GPG 管理密钥用于编辑，各主机 SSH host key 转换出的 age 身份用于运行时解密。

```text
secrets/
├── common.yaml
└── hosts/
    ├── nixos-desktop.yaml
    └── yc-hk-1.yaml
```

编辑密钥：

```bash
sops secrets/common.yaml
sops secrets/hosts/nixos-desktop.yaml
```

模块中必须通过运行时路径或模板引用密钥，不能使用 `builtins.readFile` 读取明文：

```nix
{
  config,
  cloud,
  ...
}:
{
  sops.secrets."example" =
    cloud.sops.secret {
      source = "host";
      host = "nixos-desktop";
    }
    // {
      owner = "root";
      mode = "0400";
    };

  environment.etc."example-token".source = config.sops.secrets."example".path;
}
```

Home Manager 需要密钥生成完整配置文件时，由 NixOS 层使用 `sops.templates` 渲染到 `/run/secrets/templates/`，再通过 `mkOutOfStoreSymlink` 引用。

## 展示

![RhenCloud NixOS Desktop](./show/image.png)
