# RhenCloud 的 NixOS 配置

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

本仓库使用 [transcrypt](https://github.com/elasticdog/transcrypt) 透明加密 `secrets/` 目录下的敏感文件。

### 首次克隆后初始化

```bash
transcrypt -c aes-256-cbc -p '<密码>'
```

### 查看加密文件列表

```bash
git ls-crypt
```

### 添加新密钥

```bash
# 1) 在 secrets/ 下创建文件
echo -n 'my-secret-value' > secrets/my-key

# 2) 提交（transcrypt 自动加密）
git add secrets/my-key
git commit -m "add my-key secret"
```

### 在 Nix 模块中引用

```nix
# lib/secrets.nix 提供中央 helper，通过 inputs.self 从仓库根目录解析路径
# 等效于 TypeScript 的 @/ 导入

# 在模块中使用：
{ inputs, lib, ... }:
let
  inherit (lib.strings) trim;
  readSecret = path: trim (builtins.readFile "${inputs.self}/secrets/${path}");
in {
  token = readSecret "sleepy-token";              # → secrets/sleepy-token
  apiKey = readSecret "opencode/github-token";     # → secrets/opencode/github-token
  passwordHash = builtins.readFile "${inputs.self}/secrets/password-hash";
}
```
