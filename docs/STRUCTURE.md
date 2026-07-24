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
├── systems/               # Snowfall 系统入口
│   └── x86_64-linux/
│       └── nixos-desktop/
│           ├── default.nix
│           └── hardware-configuration.nix
├── homes/                 # Snowfall Home 入口
│   └── x86_64-linux/
│       └── rhencloud@nixos-desktop/
│           └── default.nix
├── overlays/              # Snowfall Overlay 目录
│   └── mexkey3-ccid/
│       └── default.nix
└── modules/               # Snowfall 模块目录
    ├── home/             # Home Manager 模块
    └── nixos/            # NixOS 模块
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

### overlays/ - 包覆盖

自定义 Nix 包的覆盖配置。

```
overlays/
└── mexkey3-ccid/
    └── default.nix
```

### modules/nixos/ - 系统级配置

系统范围的配置模块。

```
modules/nixos/
├── core/              # 核心系统模块入口
├── desktop/           # 桌面模块入口
└── service/           # 服务模块入口
```

## 配置管理最佳实践

### 添加新主机
1. 在 `systems/<target>/<hostname>/default.nix` 创建主机入口
2. 在该目录下放置 `hardware-configuration.nix`，并在 `default.nix` 中导入
3. 生成 `hardware-configuration.nix`：
   ```bash
    sudo nixos-generate-config --root /mnt --dir ./systems/x86_64-linux/new-host
   ```
4. 在 `flake.nix` 的 `systems.hosts.<hostname>.specialArgs` 配置主机参数

### 添加新模块
1. 在 `modules/home/` 或 `modules/nixos/` 下创建新目录
2. 创建 `default.nix` 作为模块入口
3. Snowfall 会自动加载对应目录下的模块

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
