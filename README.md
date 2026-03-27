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

## 使用 agenix 管理 Home Secrets（详细教程）

本仓库现在使用 `agenix + age` 管理 Home Manager secrets：

- agenix 规则文件：`modules/home/secrets/secrets.nix`
- 加密文件目录：`modules/home/secrets/*.age`
- Home Manager 挂载配置：`modules/home/secrets/default.nix`

---

### 一、首次配置（只做一次）

#### 1) 确认私钥可用于解密

当前 `secrets.nix` 使用 SSH 公钥作为 recipient，因此你本机需要对应私钥（默认：`~/.ssh/id_ed25519`）。

```bash
ls -l ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub
```

#### 2) 确认 flake 已启用 agenix 模块

已在 `flake.nix` 中启用：

```nix
agenix.homeManagerModules.default
```

---

### 二、日常使用（修改已有 secret）

```bash
cd modules/home/secrets
agenix -e people_name.dict.yaml.age
```

或编辑另一个 secret：

```bash
cd modules/home/secrets
agenix -e mihomoConfig.yaml.age
```

- 保存退出后会自动重新加密
- 提交到 git 的始终是 `.age` 密文文件

---

### 三、如何添加新 secret（完整流程）

以新增 `musicfoxCookie` 为例。

#### 1) 在规则文件中添加 recipient 规则

编辑 `modules/home/secrets/secrets.nix`，新增：

```nix
"musicfoxCookie.age".publicKeys = [ pubKey ];
```

#### 2) 创建并编辑密文文件

```bash
cd modules/home/secrets
agenix -e musicfoxCookie.age
```

#### 3) 在 Home Manager 中声明输出路径

编辑 `modules/home/secrets/default.nix` 的 `age.secrets`，新增：

```nix
musicfoxCookie = {
  file = ./musicfoxCookie.age;
  path = "/home/${config.home.username}/.local/share/go-musicfox/cookie";
};
```

#### 4) 在业务模块引用该 secret（按需）

```nix
config.age.secrets.musicfoxCookie.path
```

#### 5) 应用配置

```bash
sudo nixos-rebuild switch --flake .#nixos-desktop
```

---

### 四、常见问题

#### 1) `no identity matched any of the recipients`

- 检查 `~/.ssh/id_ed25519` 是否存在且与 `secrets.nix` 公钥匹配
- 或在 `age.identityPaths` 中改成你实际私钥路径

#### 2) 重建后目标文件未生成

- 确认 `modules/home/secrets/default.nix` 的 `age.secrets.<name>.file` 与 `path` 已声明
- 确认对应 `.age` 文件存在
- 查看 Home Manager 激活日志定位失败步骤
