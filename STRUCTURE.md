# NixOS 配置文件结构说明

本文档详细说明了 NixOS 配置仓库的目录结构和各部分的作用。

## 目录结构概览

```
nixos/
├── flake.nix              # 主配置文件，定义 inputs 和 outputs
├── flake.lock             # 锁定依赖版本
├── README.md              # 项目说明文档
├── STRUCTURE.md           # 本文档，配置结构说明
├── .gitignore             # Git 忽略文件配置
├── hosts/                 # 各主机特定配置
│   └── nixos-desktop/
│       ├── configuration.nix        # 主机系统配置
│       └── hardware-configuration.nix # 硬件配置
└── modules/               # 模块化配置
    ├── home/             # Home Manager 用户配置
    ├── overlays/         # Nix 包覆盖
    └── system/           # 系统级配置
```

## 核心文件说明

### flake.nix
主配置文件，定义了：
- Nix 缓存镜像源配置
- 外部依赖（inputs）
- 系统和用户配置的构建逻辑
- 全局变量（username, hostname, stateVersion）

### flake.lock
自动生成的依赖版本锁定文件，确保构建的可重现性。

## hosts/ 目录

每个主机一个子目录，包含该主机特有的配置：

### configuration.nix
主机的系统配置入口，导入：
- 硬件配置
- 系统核心模块
- 桌面环境模块
- 服务模块

### hardware-configuration.nix
由 NixOS 自动生成，包含硬件特定配置，通常不应手动修改。

## modules/ 目录

### modules/home/ - Home Manager 配置

用户级配置，通过 Home Manager 管理。

#### default.nix
Home Manager 主配置文件，包含：
- 用户基本信息
- 基础软件包
- Git、GPG、SSH 等工具配置
- 导入子模块

#### 子目录结构

```
modules/home/
├── config/           # 应用配置文件
│   ├── fastfetch/   # Fastfetch 终端信息工具配置
│   └── kitty/       # Kitty 终端配置
├── core/            # 核心工具配置
│   ├── fish/       # Fish Shell 配置
│   └── ghostty/    # Ghostty 终端配置
├── desktop/         # 桌面环境配置
│   ├── base/       # 基础桌面配置
│   ├── hyprland/   # Hyprland 窗口管理器配置
│   ├── kitty/      # Kitty 终端配置
│   ├── tofi/       # Tofi 启动器配置
│   └── ...         # 其他桌面应用配置
├── dev/            # 开发环境配置
│   ├── node.nix    # Node.js 开发环境
│   └── python.nix  # Python 开发环境
├── secrets/        # 敏感信息管理
│   ├── default.nix      # Home Manager secrets 配置
│   ├── secrets.nix      # Agenix 规则文件
│   └── *.age            # 加密的敏感文件
├── service/        # 用户级服务配置
│   └── mpd.nix     # MPD 音乐播放服务
└── user/           # 用户特定配置
    ├── dev/        # 用户开发配置
    └── ...         # 其他用户配置
```

#### secrets/ 子目录
使用 agenix 管理敏感信息：
- `secrets.nix`: 定义哪些文件需要加密
- `default.nix`: 定义解密后的文件存放位置
- `*.age`: 加密后的敏感文件

### modules/overlays/ - 包覆盖

自定义 Nix 包的覆盖配置。

```
modules/overlays/
├── default.nix          # 导入所有覆盖
├── mexkey3-ccid.nix     # mexkey3-ccid 包覆盖
└── pyprland.nix        # pyprland 包覆盖
```

### modules/system/ - 系统级配置

系统范围的配置模块。

```
modules/system/
├── core/              # 核心系统配置
│   ├── boot.nix       # 启动配置
│   ├── common.nix     # 通用配置
│   ├── env.nix        # 环境变量配置
│   ├── fcitx5.nix     # 输入法配置
│   ├── fonts.nix      # 字体配置
│   ├── nvidia.nix     # NVIDIA 显卡配置
│   ├── proxy.nix      # 代理配置
│   └── config.dae     # DAE 代理配置
├── desktop/           # 桌面环境配置
│   ├── desktop.nix    # 桌面环境基础配置
│   ├── steam.nix      # Steam 游戏平台配置
│   ├── theme.nix      # 主题配置
│   └── zen.nix        # Zen Browser 配置
└── service/           # 系统服务配置
    ├── bluetooth.nix  # 蓝牙服务
    ├── displayManagers.nix # 显示管理器
    └── sound.nix      # 音频服务
```

## 配置管理最佳实践

### 添加新主机
1. 在 `hosts/` 下创建新主机目录
2. 复制并修改 `configuration.nix`
3. 生成 `hardware-configuration.nix`：
   ```bash
   sudo nixos-generate-config --root /mnt --dir ./hosts/new-host
   ```
4. 在 `flake.nix` 中添加新主机配置

### 添加新模块
1. 在 `modules/home/` 或 `modules/system/` 下创建新目录
2. 创建 `default.nix` 作为模块入口
3. 在相应的 `default.nix` 中导入新模块

### 管理敏感信息
1. 使用 agenix 加密敏感文件：
   ```bash
   cd modules/home/secrets
   agenix -e new-secret.age
   ```
2. 在 `secrets.nix` 中添加规则
3. 在 `default.nix` 中定义解密路径

### 更新依赖
```bash
nix flake update
```

### 应用配置
```bash
sudo nixos-rebuild switch --flake .#hostname
```

## 常用命令

### 查看配置差异
```bash
nixos-rebuild build --flake .#hostname
nix diff-closures /run/current-system result
```

### 测试配置
```bash
sudo nixos-rebuild test --flake .#hostname
```

### 回滚配置
```bash
sudo nixos-rebuild switch --rollback
```

### 清理旧配置
```bash
sudo nix-collect-garbage -d
```

## 注意事项

1. **不要手动修改** `hardware-configuration.nix`
2. **敏感信息** 必须使用 agenix 加密
3. **定期更新** 依赖和系统包
4. **提交前检查** 是否有敏感文件泄露
5. **备份重要数据** 在大规模修改前

## 参考资源

- [NixOS 官方文档](https://nixos.org/manual/nixos/stable/)
- [Home Manager 手册](https://nix-community.github.io/home-manager/)
- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [Agenix 文档](https://github.com/ryantm/agenix)
