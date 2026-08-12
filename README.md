# RhenCloud 的 NixOS 配置

[![Mirror Repository](https://github.com/RhenCloud/NixOS-Config/actions/workflows/mirror.yml/badge.svg)](https://github.com/RhenCloud/NixOS-Config/actions/workflows/mirror.yml)
[![Build & Push to Cachix](https://github.com/RhenCloud/NixOS-Config/actions/workflows/cachix.yml/badge.svg)](https://github.com/RhenCloud/NixOS-Config/actions/workflows/cachix.yml)

## 镜像仓库

本仓库同时托管于以下平台，内容保持同步：

| 平台 | 链接 |
|------|------|
| **GitHub** | https://github.com/RhenCloud/NixOS-Config |
| **GitLab** | https://gitlab.com/RhenCloud/NixOS-Config |
| **Codeberg** | https://codeberg.org/RhenCloud/NixOS-Config |
| **cnb.cool** | https://cnb.cool/RhenCloud/NixOS-Config |

## 介绍

| 项目       | 实现                                                           |
| ---------- | -------------------------------------------------------------- |
| 启动器     | [Noctalia Shell](https://noctalia.dev)                         |
| 顶栏       | [Noctalia Shell](https://noctalia.dev)                         |
| 终端       | [Kitty](https://github.com/kovidgoyal/kitty)                   |
| 编辑器     | [VSCode](https://code.visualstudio.com/)                       |
| 字体       | [Maple Mono NF CN](https://github.com/subframe7536/Maple-font) |
| 主题       | [Dracula](https://draculatheme.com)                            |
| Shell      | [Fish](https://fishshell.com)                                  |
| 桌面环境   | [Hyprland](hypr.land)                                          |
| 输入法     | [Fcitx5](https://fcitx-im.org) · [Rime](rime.im)               |
| 音乐播放   | [go-musicfox](https://github.com/go-musicfox/go-musicfox)      |
| 截图工具   | [Flameshot](https://flameshot.org/)                            |
| 剪贴板     | [Clipse](https://github.com/savedra1/clipse)                   |
| 壁纸管理器 | [Waypaper](https://github.com/anufrievroman/waypaper)          |
| 桌面歌词   | [Waylyrics](https://github.com/waylyrics/waylyrics)            |
| 浏览器     | [Zen Browser](https://zen-browser.app)                         |

## 展示

![RhenCloud NixOS Desktop](./show/image.png)

## 管理 Secrets

本仓库使用 [sops-nix](https://github.com/Mic92/sops-nix) 管理 `secrets/` 目录下的敏感文件。
加密由 GPG 管理员密钥（编辑）与各主机 SSH host key（运行时解密）共同持有。

### 目录结构

```
secrets/
├── common.yaml                # 所有主机共享的密钥
└── hosts/
    ├── nixos-desktop.yaml     # desktop 专属密钥
    └── yc-hk-1.yaml           # 服务器专属密钥
```

### 查看 / 编辑加密文件

```bash
# 用 GPG 管理员密钥解密后编辑（sops 支持 JSON/YAML 结构编辑）
sops secrets/common.yaml
sops secrets/hosts/nixos-desktop.yaml
```

### 添加新主机

```bash
# 1) 获取主机 SSH host public key
ssh-keyscan <host>  # 或从服务器读取 /etc/ssh/ssh_host_ed25519_key.pub

# 2) 转换为 age 公钥
nix shell nixpkgs#ssh-to-age -c ssh-to-age < pubkey

# 3) 在 .sops.yaml 中为新主机添加 age recipient，然后更新已加密文件
sops updatekeys secrets/common.yaml
sops updatekeys secrets/hosts/<host>.yaml
```

### 在 Nix 模块中引用

```nix
# 声明 secret（运行时解密到 /run/secrets/<name>）
sops.secrets."sleepy-token" = {
  sopsFile = ./secrets/common.yaml;
  owner = "root";
  mode = "0400";
};

# 用模板渲染含密钥的完整配置（activation 时替换明文）
sops.templates."sleepy-env" = {
  content = "sleepy_main_secret=${config.sops.placeholder."sleepy-token"}\n";
  mode = "0400";
};
# 引用: config.sops.secrets."sleepy-token".path / config.sops.templates."sleepy-env".path
```
