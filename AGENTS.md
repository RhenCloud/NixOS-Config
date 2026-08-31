# AGENTS.md

RhenCloud 的 NixOS 系统配置，使用 **Cloud Nix Framework** 以 Nix flake 管理。

## 仓库结构

```text
flake.nix                              # inputs + cloud.lib.mkFlake 入口
flake/extra-outputs.nix                # 仅保留 ISO 等非约定 outputs
apps/<name>/default.nix                # 自动发现的 flake app
checks/<name>/default.nix              # 自动发现的 flake check
shells/<name>/default.nix              # 自动发现的 devShell
formatter/default.nix                  # flake formatter
deploy/default.nix                     # deploy-rs 节点配置
hosts/<host>/                           # NixOS 主机入口；meta.nix 必须声明 system
homes/<user>/<host>.nix                # 每用户、每主机的 Home Manager 入口
modules/_common/                       # 所有角色共享模块
modules/desktop/                       # desktop 角色模块
modules/server/                        # server 角色模块
modules/desktop/roles/nixos.nix        # 桌面角色能力聚合
modules/server/roles/nixos.nix         # 服务器角色能力聚合
packages/<name>/default.nix            # 自动发现的自定义包
packages/<system>/<name>/default.nix   # 明确限定架构的推荐包布局
overlays/<name>/default.nix            # 自动发现的 overlay
secrets/                               # sops 加密密钥
patches/                               # 本地补丁
```

## Cloud Nix Framework 约定

入口使用嵌套命名空间，不使用已弃用的扁平参数：

```nix
inputs.cloud.lib.mkFlake {
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

自动发现映射：

- `hosts/<host>/default.nix` + `hosts/<host>/meta.nix` → `nixosConfigurations.<host>`
- `homes/<user>/<host>.nix` → `homeConfigurations."<user>@<host>"`
- `packages/<name>/default.nix` → `packages.<system>.<name>`
- `packages/<system>/<name>/default.nix` → 指定架构的 `packages.<system>.<name>`
- `overlays/<name>/default.nix` → `overlays.<name>`
- `apps/<name>/default.nix` → `apps.<system>.<name>`
- `checks/<name>/default.nix` → `checks.<system>.<name>`
- `shells/<name>/default.nix` → `devShells.<system>.<name>`
- `formatter/default.nix` → `formatter.<system>`
- `deploy/default.nix` → `deploy`

主机元数据：

```nix
# hosts/<host>/meta.nix
{
  system = "x86_64-linux";
  roles = [ "desktop" ];
  home.embed = true;
}
```

- `system` 必须在 `meta.nix` 显式声明，不再写入目录后缀。
- `roles`、`home.embed`、`home.useGlobalPkgs` 只写在 `meta.nix`。
- `default.nix` 只由 NixOS module system 求值，不要在其中写框架元数据。

模块 magic 文件：

- `default.nix`：NixOS 与 Home Manager 两侧加载，只放共享 options / 中性接口。
- `nixos.nix`：仅 NixOS。
- `home.nix`：仅 Home Manager。
- `mod.nix` 和其他普通 `.nix` 文件不会自动加载，必须由 magic 文件显式 import。
- 模块目录可通过 `meta.nix` 声明 `requires`、`after`、`before`、`wants`、`conflicts`；只有存在明确依赖时才添加。
- 角色聚合器的 `meta.nix` 应 `requires` 它实际设置选项的模块；读取 `config.my.*` 的模块应依赖 `_common.options`，避免主机覆盖禁用后出现延迟的 option 缺失。

角色规则：

- `modules/_common/` 始终注入。
- `modules/<role>/` 的 `nixos.nix` / `home.nix` 只注入 `meta.nix` 中匹配该角色的主机和 home。
- `modules/**/default.nix` 是共享接口，始终注入。
- 角色能力仍由 `rhencloud.roles.<role>.enable` 聚合启用。

## 当前主机和用户

- `nixos-desktop`：desktop，用户 `rhencloud`
- `yc-hk-1`：server，用户 `rhencloud`、`wyf9`、`advan10`
- `nixos-homeserver`：server，用户 `rhencloud`

`yc-hk-1` 的 Home Manager profiles 通过 deploy-rs 独立部署。`hosts/yc-hk-1/meta.nix` 使用 `home.embed = false`，框架仍生成独立 `homeConfigurations`，但不向 NixOS 嵌入 Home Manager。

## 配置要点

- 主用户：`rhencloud`。系统 shell 的自动 fish 切换仅作用于主用户，其他用户保持其显式 shell。
- 频道：`nixos-unstable`。
- `stateVersion`：`26.11`。
- 窗口管理器：Hyprland、Niri、Mango。
- 主题：Stylix + Dracula。
- Nix 格式化：nixfmt-rfc-style（`nixfmt`）。
- `modules/_common/externals/nixos.nix` 通过 `cloud.homeManager.backupFileExtension = "backup"` 安全配置嵌入式 HM 备份策略。
- `allowUnfree` 与 `permittedInsecurePackages` 由 `flake.nix` 的 `nixpkgs.config` 统一控制。
- `outputs.expected` 用于防止关键 hosts、homes、packages、apps 在重构中静默丢失。
- `hardware-configuration.nix` 不要手动修改；使用 `nixos-generate-config` 重新生成。

## 外部模块与 overlays

外部模块按目标拆分：

```text
modules/_common/externals/home.nix
modules/_common/externals/nixos.nix
modules/desktop/externals/home.nix
modules/desktop/externals/nixos.nix
```

不要把 NixOS-only 模块导入 Home Manager，反之亦然。

框架自动导出并应用 `self.overlays`。自动发现的 overlays 与 `nixpkgs.config` 统一用于 NixOS、独立/嵌入式 Home Manager、packages、checks、devShells、apps 和 formatter。不要在模块中重复配置 `nixpkgs.overlays` 或 `nixpkgs.config`。

## 模块聚合注意事项

`modules/desktop/dev/home.nix` 会：

- 导入子目录中的 `mod.nix`。
- 导入同目录 flat `.nix`。
- 排除 `home.nix`、`nixos.nix`、`default.nix` 和当前禁用的 `lucy.nix`。

在假定模块生效前，先确认它是 magic 文件，或已被相应聚合器 import。

## Secrets

由 sops-nix 管理：

```text
secrets/common.yaml
secrets/hosts/<host>.yaml
```

编辑密钥：

```bash
sops secrets/common.yaml
sops secrets/hosts/nixos-desktop.yaml
```

模块规则：

- 使用 `config.sops.secrets."<name>".path`。
- 使用 `sops.templates` 渲染含秘密的完整配置。
- 使用 `cloud.sops.secret` helper 指定密钥来源，**不要**手写 `self.outPath + "/secrets/..."`：

  ```nix
  sops.secrets."password-hash" =
    cloud.sops.secret { source = "common"; }
    // { neededForUsers = true; };

  sops.secrets."mihomo-proxies" =
    cloud.sops.secret {
      source = "host";
      host = "nixos-desktop";
    }
    // { owner = "root"; };
  ```

- `cloud.sops.secret { source = "host"; }` 省略 host 时返回动态 NixOS module；只有适合放入 `imports` 且不需要条件声明或追加 owner/mode 时才使用。独立 Home Manager 配置继续显式指定 host。
- Home Manager 通过 `mkOutOfStoreSymlink "/run/secrets/templates/<file>"` 引用 NixOS 渲染结果。
- 绝不使用 `builtins.readFile` 读取密钥。

## 常用命令

```bash
nix run .#build -- nixos-desktop
nix run .#test -- nixos-desktop
nix run .#switch -- nixos-desktop
nix run .#deploy -- yc-hk-1

nixos-rebuild build --flake .#nixos-desktop
nix build '.#homeConfigurations."rhencloud@nixos-desktop".activationPackage'

nix flake update
nix flake update <input-name>
nix flake check --all-systems
nix diff-closures /run/current-system result
sudo nixos-rebuild switch --rollback
sudo nix-collect-garbage -d
nix develop .#python
```

求值尚未加入 Git index 的迁移文件时使用 path flake：

```bash
nix eval "path:$PWD#nixosConfigurations.nixos-desktop.config.system.build.toplevel.drvPath" \
  --raw --option allow-import-from-derivation true
```

## 常见修改模式

### 新增 Home Manager 模块

创建 `modules/<scope>/<name>/home.nix`。如果需要共享 option，再创建 `default.nix`。普通辅助文件必须从 `home.nix` 导入。

### 新增 NixOS 模块

创建 `modules/<scope>/<name>/nixos.nix`。如果需要共享 option，再创建 `default.nix`。普通辅助文件必须从 `nixos.nix` 导入。

### 新增角色

1. 创建 `modules/<role>/roles/nixos.nix`，定义 `rhencloud.roles.<role>.enable`。
2. 在主机的 `meta.nix` 中加入 `roles = [ "<role>" ];`。
3. 在主机配置中启用 `rhencloud.roles.<role>.enable = true;`。

### 新增主机

1. 创建 `hosts/<host>/meta.nix`，至少声明 `system` 与 `roles`。
2. 创建 `hosts/<host>/default.nix`，放入 hostname、hostPlatform 和机器专属配置。
3. 放入 `hardware-configuration.nix` 或 disko 配置。
4. 按需创建 `homes/<user>/<host>.nix`。
5. 将关键 output 名加入 `flake.nix` 的 `outputs.expected`。

### 新增 flake input

1. 在 `flake.nix` 添加 input。
2. 外部模块加入对应 `externals/home.nix` 或 `externals/nixos.nix`。
3. app/check/package/shell/deploy 配置放入对应约定目录；只有非约定 output 才加入 `flake/extra-outputs.nix`。

## 检查流程

```bash
find . -path './.git' -prune -o -path './result' -prune -o -name '*.nix' -type f -print0 \
  | xargs -0 -n1 nix-instantiate --parse
nixfmt --check $(find . -path './.git' -prune -o -path './result' -prune -o -name '*.nix' -type f -print)
statix check .
deadnix --fail -L .
nix flake check --all-systems --option allow-import-from-derivation true
```

## 风格与安全

- 代码注释和面向用户的字符串使用简体中文。
- 不主动 commit / push，除非用户明确要求。
- 不回滚已有迁移改动。
- 不修改 `wallpapers` 特殊条目。
- 不修改 `hardware-configuration.nix`。
- 不把密钥或运行时明文放入 Nix store。
