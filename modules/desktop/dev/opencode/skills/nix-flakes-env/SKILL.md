---
name: nix-flakes-env
description: |
  使用 Nix Flakes 创建和管理项目开发环境。涵盖 flake.nix 模板、多语言 devShell、Cloud Nix Framework 集成、输入管理、direnv 配置等。
  Use when: 创建新项目需要 Nix 开发环境、配置 flake.nix、添加 devShell、管理 flake inputs、设置 direnv、集成语言工具链（Python/Rust/Go/Node/Bun/Deno）、或需要 nix 环境模板。
  Use ONLY when the user is creating or configuring a Nix flake-based project environment.
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
---

# Nix Flakes 项目环境配置

## 核心原则

- **优先使用 Nix 管理依赖**：能用 Flakes 解决的，不用 npm/pip/cargo install
- **inputs 使用 nixos-unstable** 频道
- **格式化**：所有 `.nix` 文件用 `nixfmt` 格式化
- **注释**：使用中文简体

---

## 1. 基础 flake.nix 模板

### 1.1 最简模板

```nix
{
  description = "项目描述";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ ];
        };
      });
}
```

### 1.2 带 formatter 的模板

```nix
{
  description = "项目描述";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ ];
        };
        formatter = pkgs.pkgs.nixfmt;
      });
}
```

---

## 2. 多语言 devShell 配方

### 2.1 Python

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
    python312
    python312Packages.pip
    python312Packages.virtualenv
  ];
  shellHook = ''
    export PYTHONPATH="$PWD:$PYTHONPATH"
  '';
};
```

**Python + 常用工具**：

```nix
buildInputs = with pkgs; [
  (python312.withPackages (ps: with ps; [
    pip
    setuptools
    wheel
  ]))
  ruff
  pyright
  uv
];
```

### 2.2 Rust

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer
  ];
};
```

**Rust + mold 加速链接**：

```nix
buildInputs = with pkgs; [
  rustc cargo clippy rustfmt rust-analyzer
  mold-wrapped
  openssl pkg-config
];
shellHook = ''
  export RUSTFLAGS="-C linker=clang -C link-arg=-fuse-ld=mold"
'';
```

### 2.3 Go

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
    go
    gopls
    golangci-lint
  ];
  shellHook = ''
    export GOPATH="$HOME/go"
    export PATH="$GOPATH/bin:$PATH"
  '';
};
```

### 2.4 Node.js / TypeScript

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
    nodejs_22
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.prettier
    biome
    fnm
  ];
  shellHook = ''
    eval "$(fnm env --use-on-cd)"
  '';
};
```

### 2.5 Bun

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
    bun
    biome
    nodejs_22
  ];
};
```

### 2.6 Deno

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
    deno
    biome
  ];
  shellHook = ''
    export DENO_DIR="$XDG_CACHE_HOME/deno"
  '';
};
```

### 2.7 Java / Kotlin

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
    jdk21
    gradle
    kotlin
    kotlin-language-server
    maven
  ];
  shellHook = ''
    export JAVA_HOME="${pkgs.jdk21}"
  '';
};
```

---

## 3. 多语言混合环境

```nix
{
  description = "全栈项目开发环境";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bun
            nodejs_22
            go
            python312
            rustc cargo
            sqlite
            just
            watchexec
            pkgs.nixfmt
            shellcheck
          ];

          shellHook = ''
            export GOPATH="$HOME/go"
            export PATH="$GOPATH/bin:$PATH"
          '';
        };
      });
}
```

---

## 4. 使用项目特定 version 的包

当需要使用特定版本的包，覆盖 nixpkgs：

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [
    (nodejs_22.override { openssl = pkgs.openssl_3; })
  ];
};
```

或者用 overlay 添加非 nixpkgs 的包：

```nix
let
  overlays = [
    (final: prev: {
      my-custom-tool = final.callPackage ./nix/my-tool.nix { };
    })
  ];
  pkgs = import nixpkgs { inherit system overlays; };
in ...
```

---

## 5. direnv 集成

创建 `.envrc`：

```bash
if ! has nix_direnv_version; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.0.6/direnvrc" "sha256-ksIpIRQfn4n2xKMyrrZbWQJdYRdLIpZIiCe33mYs0BQ="
fi

use flake
```

然后运行 `direnv allow`。

---

## 6. Cloud Nix Framework 项目模板

用户项目需要同时管理 NixOS、Home Manager、packages 与 overlays 时：

```nix
{
  description = "My project";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cloud = {
      url = "github:RhenCloud/Cloud-Nix-Framework";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs:
    inputs.cloud.lib.mkFlake {
      inherit inputs;
      systems = [ "x86_64-linux" ];
    };
}
```

框架按约定发现 `hosts/`、`homes/`、`modules/`、`packages/` 与 `overlays/`。单树模块使用 `default.nix`、`nixos.nix`、`home.nix` 区分共享、NixOS 和 Home Manager 模块。

---

## 7. 环境变量与 shellHook

按优先级从高到低决定 shellHook 方案：

1. 环境变量少：直接写在 `mkShell` 的 env 属性
2. 需要动态计算：用 `shellHook`
3. 持久化环境：用 direnv 的 `.envrc`

```nix
devShells.default = pkgs.mkShell {
  buildInputs = with pkgs; [ ];

  STATIC_VAR = "value";
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.openssl ];

  shellHook = ''
    export DYNAMIC_VAR="$(some_command)"
    echo "DevShell 已加载"
  '';
};
```

---

## 8. 常用工具清单

### 通用 CLI 工具

`just` (命令执行器), `watchexec` (文件监听), `fd` (查找), `ripgrep` (搜索), `jq` (JSON), `yq` (YAML),

### 格式化与检查

`nixfmt` (Nix), `ruff` (Python), `clippy` + `rustfmt` (Rust), `gofumpt` (Go), `biome` (JS/TS/CSS), `prettier` (JS/JSON/MD), `alejandra` (Nix 备选), `shellcheck` (Shell)

### 语言服务器

`nil` / `nixd` (Nix), `pyright` (Python), `rust-analyzer` (Rust), `gopls` (Go), `typescript-language-server` (TS/JS), `bun` (自带 TS LSP), `deno` (自带 LSP), `kotlin-language-server` (Kotlin)

---

## 9. 操作流程

### 创建新项目的 Nix 环境

1. 创建 `flake.nix`（参考上方模板）
2. 添加所需语言的 `buildInputs`
3. 创建 `.envrc` 并 `direnv allow`
4. 运行 `nix flake check` 验证 flake 格式
5. 运行 `nix fmt` 格式化所有 nix 文件
6. 运行 `nix develop` 或通过 direnv 自动进入

### 为现有项目添加 Nix 环境

1. 分析项目依赖（`package.json`、`pyproject.toml`、`Cargo.toml`、`go.mod` 等）
2. 在对应的 nixpkgs 中找到对应包名（不猜测包名，用 `nixos_nix` 工具查询）
3. 创建 `flake.nix`，将依赖映射为 nix 包
4. 创建 `.envrc`
5. 建议在项目根目录创建 `.direnv/` 忽略规则（`.gitignore`）

### 更新 flake inputs

```bash
nix flake update              # 更新所有
nix flake update nixpkgs      # 更新单个 input
nix flake lock --refresh      # 强制刷新
```

---

## 10. 检查清单

创建 flake 环境时确认：

- [ ] `description` 字段已填写
- [ ] `nixpkgs.url` 使用 `nixos-unstable`
- [ ] `flake-utils` input 已添加（如需要跨系统支持）
- [ ] `buildInputs` `buildInputs` 包含所有必要包
- [ ] `shellHook` 中设置了必要的环境变量
- [ ] `.envrc` 存在且 `direnv allow` 已执行
- [ ] `nix flake check` 通过
- [ ] `nix fmt` 已运行
- [ ] `.gitignore` 包含 `.direnv/` 和 `result`
