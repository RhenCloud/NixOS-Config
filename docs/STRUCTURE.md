# NixOS 配置文件结构说明

本文档说明本仓库迁移到 Snowveil 后的目录结构、自动发现规则和常见修改方式。

## 目录结构概览

```text
.
├── flake.nix
├── flake.lock
├── flake/
│   └── extra-outputs.nix
├── apps/
├── checks/
├── shells/
├── formatter/
├── deploy/
├── hosts/
│   ├── nixos-desktop/
│   │   ├── meta.nix
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   ├── nixos-homeserver/
│   │   ├── meta.nix
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   └── yc-hk-1/
│       ├── meta.nix
│       ├── default.nix
│       └── disko-config.nix
├── homes/
│   ├── advan10/
│   │   └── yc-hk-1.nix
│   ├── rhencloud/
│   │   ├── nixos-desktop.nix
│   │   ├── nixos-homeserver.nix
│   │   └── yc-hk-1.nix
│   └── wyf9/
│       └── yc-hk-1.nix
├── modules/
│   ├── _common/
│   ├── desktop/
│   └── server/
├── packages/
├── overlays/
├── secrets/
├── patches/
└── scripts/
```

## Flake 入口

`flake.nix` 定义 inputs，然后使用框架的嵌套命名空间：

```nix
inputs.snowveil.lib.mkFlake {
  inherit inputs systems;

  nixpkgs.config = {
    allowUnfree = true;
  };

  outputs = {
    extra = import ./flake/extra-outputs.nix { inherit inputs; };
    expected = {
      hosts = [ "nixos-desktop" ];
      homes = [ "rhencloud@nixos-desktop" ];
    };
  };
}
```

Snowveil 自动发现：

- `hosts/` → `nixosConfigurations`
- `homes/` → `homeConfigurations`
- `modules/` → NixOS / Home Manager 自动模块及模块导出
- `packages/` → `packages`
- `overlays/` → `overlays`
- `apps/` → `apps`
- `checks/` → `checks`
- `shells/` → `devShells`
- `formatter/` → `formatter`
- `deploy/` → `deploy`

`flake/extra-outputs.nix` 只补充暂未采用目录约定的 ISO NixOS configuration。

`nixpkgs.config` 统一配置 `allowUnfree`、`permittedInsecurePackages` 等 nixpkgs 选项；自动发现的 overlays 会应用到 NixOS、独立/嵌入式 Home Manager 以及所有 per-system outputs。`outputs.expected` 会由 `snowveil-discovery` 检查验证，防止目录重构时静默丢失关键 output。

## hosts/：NixOS 主机入口

目录格式固定为：

```text
hosts/<hostname>/meta.nix
hosts/<hostname>/default.nix
```

`meta.nix` 是框架读取的静态元数据：

```nix
{
  system = "x86_64-linux";
  roles = [ "desktop" ];
  home.embed = true;
}
```

例如 `hosts/nixos-desktop/` 会生成 `nixosConfigurations.nixos-desktop`。

- `meta.nix` 负责 `system`、`roles`、`home.embed`、`home.useGlobalPkgs` 等发现期策略。
- `default.nix` 只由 NixOS module system 求值，负责导入硬件或 disko 配置、设置 hostname/hostPlatform、配置网络和存储、启用角色与主机独有服务。
- 不要在 `default.nix` 顶层写 `role` / `roles` 等框架元数据。

`hardware-configuration.nix` 不要手动修改，应使用：

```bash
sudo nixos-generate-config --root /mnt --dir ./hosts/new-host
```

## homes/：Home Manager 入口

每主机 Home Manager 文件格式为：

```text
homes/<user>/<host>.nix
```

输出名称为：

```text
homeConfigurations."<user>@<host>"
```

如果需要多个主机共享同一用户配置，可增加 `homes/<user>/default.nix`。

`yc-hk-1` 的 `rhencloud`、`wyf9`、`advan10` 三个 Home Manager profiles 当前通过 deploy-rs 独立部署。该主机在 `meta.nix` 中设置 `home.embed = false`，因此框架生成独立配置但不嵌入 NixOS。

## modules/：单树模块

Snowveil 使用单棵模块树，依靠文件名区分目标：

| 文件名 | 注入目标 | 用途 |
| --- | --- | --- |
| `options.nix` | NixOS + Home Manager | 声明两侧共享的 option 接口，并优先加载 |
| `default.nix` | NixOS + Home Manager | 平台中性的共享实现 |
| `nixos.nix` | 仅 NixOS | 系统服务、硬件、系统包等 |
| `home.nix` | 仅 Home Manager | 用户程序、dotfiles、用户服务等 |
| `meta.nix` | 发现/组合阶段 | 声明模块依赖和排序关系 |

框架会递归发现任意深度的 magic 文件。`mod.nix`、普通 `.nix` 文件和资源文件不会被直接发现，必须由 magic 文件显式导入。

模块目录的 `meta.nix` 可按需声明：

```nix
{
  requires = [ "必需模块" ];
  wants = [ "可选模块" ];
  after = [ "排序在其后" ];
  before = [ "排序在其前" ];
  conflicts = [ "冲突模块" ];
}
```

只有存在明确模块级关系时才添加，避免把运行时 systemd 依赖误写成求值期模块依赖。

角色聚合器的 `meta.nix` 会硬依赖其实际设置选项的其他模块；读取 `config.my.*` 的公共/桌面模块也依赖 `_common.options`。这样通过主机 `meta.nix` 的 `modules.<name> = false` 禁用必要模块时，会在组合阶段得到明确的依赖错误，而不是进入深层模块求值后才出现 option 缺失。

### `_common/`

`modules/_common/` 始终注入所有角色，用于通用系统模块、通用 Home Manager 模块、外部模块导入和全局 options。

### `desktop/`

`modules/desktop/` 仅注入包含 `desktop` role 的主机及其 home，包含 Hyprland、Niri、Mango、Noctalia、Kitty、Fcitx5、Stylix、桌面应用与游戏。

### `dev/`

`modules/dev/` 仅向包含 `dev` role 的 home 注入开发环境。根目录的 `options.nix` 声明共享的 `rhencloud.roles.dev.enable` option，`home.nix` 只负责在 role option 启用时聚合各项开发能力。

语言工具链、编辑器和 AI 编程工具分别位于 `modules/dev/<name>/`，每项能力使用自己的 `options.nix` / `home.nix` magic 文件，由框架独立发现。`lucy/mod.nix` 作为当前禁用的非 magic 实现保留，不会被框架自动发现。开发环境因此不再隐式属于 `desktop` role。

### `server/`

`modules/server/` 仅注入 `roles = [ "server" ]` 的主机，包含 PostgreSQL、FRP、Vaultwarden、PDS、RustDesk、NextBridge 等服务，以及服务器角色聚合器。

## 角色过滤

角色写在主机静态元数据中：

```nix
# hosts/example/meta.nix
{
  system = "x86_64-linux";
  roles = [
    "desktop"
    "dev"
  ];
}
```

主机模块只启用实际能力：

```nix
{ ... }:
{
  imports = [ ./hardware-configuration.nix ];
  rhencloud.roles.desktop.enable = true;
}
```

Home Manager-only role 在对应 home 入口中启用：

```nix
{
  rhencloud.roles.dev.enable = true;
}
```

角色目录控制模块是否注入；实际能力仍通过 `rhencloud.*.enable` 选项启用。

## 外部模块与 Home Manager

外部 NixOS 与 Home Manager 模块分别放置，避免把单端模块注入错误的模块系统：

```text
modules/_common/externals/nixos.nix
modules/_common/externals/home.nix
modules/desktop/externals/nixos.nix
modules/desktop/externals/home.nix
```

框架为独立与嵌入式 Home Manager 提供统一配置过的 nixpkgs。公共 NixOS 模块使用：

```nix
snowveil.homeManager.backupFileExtension = "backup";
```

该选项只在实际嵌入 HM 的主机上生效，因此 `home.embed = false` 的服务器也可安全导入同一公共模块。

## packages/ 与 overlays/

通用包布局：

```text
packages/<name>/default.nix
```

明确单架构的推荐布局：

```text
packages/<system>/<name>/default.nix
```

新增 overlay：

```text
overlays/<name>/default.nix
```

框架会生成对应 flake output，并将自动发现的 overlays 与 `nixpkgs.config` 统一用于这些包及其他 per-system outputs。

约定式扩展输出放在：

```text
apps/<name>/default.nix
checks/<name>/default.nix
shells/<name>/default.nix
formatter/default.nix
deploy/default.nix
```

## Secrets

敏感信息统一由根目录 `secrets/` 管理：

```text
secrets/common.yaml
secrets/hosts/<host>.yaml
```

规则：

1. 使用 `snowveil.sops.secret` 选择 common 或 host 密钥文件。
2. 模块中声明 `sops.secrets` 或 `sops.templates`，运行时通过 `config.sops.secrets."<name>".path` 引用。
3. Home Manager 需要完整密钥配置时，NixOS 先渲染到 `/run/secrets/templates/`，HM 再创建 out-of-store symlink。
4. 独立 Home Manager 中显式指定 host；不要假设存在 `config.networking.hostName`。
5. 禁止用 `builtins.readFile` 把秘密读入 Nix store。

示例：

```nix
sops.secrets."example" =
  snowveil.sops.secret {
    source = "host";
    host = "nixos-desktop";
  }
  // {
    owner = "root";
    mode = "0400";
  };
```

## 常见操作

### 新增主机

1. 创建 `hosts/<host>/meta.nix`，声明 `system` 和 `roles`。
2. 创建 `hosts/<host>/default.nix`。
3. 添加或生成硬件 / disko 配置。
4. 在主机模块中启用对应 `rhencloud.roles.<role>.enable`。
5. 按需创建 `homes/<user>/<host>.nix`。
6. 将关键 output 加入 `flake.nix` 的 `outputs.expected`。

### 新增模块

1. 选择 `_common`、`desktop`、`dev` 或 `server`。
2. 创建 `modules/<role>/<name>/`。
3. 共享 options 放 `options.nix`，中性实现放 `default.nix`，系统实现放 `nixos.nix`，用户实现放 `home.nix`。
4. 如果使用 `mod.nix` 或普通文件，必须从 magic 文件显式 import。
5. 只有存在真实依赖、排序或冲突关系时才创建 `meta.nix`。
6. 用 `nix eval` 验证相关主机和 home。

### 新增 input

1. 在 `flake.nix` 添加 input。
2. 外部模块加入对应 `modules/*/externals/{nixos,home}.nix`。
3. 包、app、check、shell 或 deploy 配置放入对应的约定目录；只有无法用约定表达的 output 才加入 `flake/extra-outputs.nix`。

### 构建与检查

```bash
nix run .#build -- nixos-desktop
nix run .#test -- nixos-desktop
nix run .#switch -- nixos-desktop
nix run .#deploy -- yc-hk-1
nix flake check --all-systems --option allow-import-from-derivation true
```

## 注意事项

- 路径中的 `@` 是合法 flake output 名称，但命令行通常需要引号。
- Home Manager 冲突文件使用 `.backup` 后缀备份。
- 不要手动编辑 `hardware-configuration.nix`。
- 不要把密钥、token 或解密后的 sops 内容写入 Nix store。
- `wallpapers` 是独立 Git 子模块/特殊工作树条目，迁移时不要改动。
