#!/usr/bin/env python3
import os
import re

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def remove(*paths):
    for p in paths:
        full = os.path.join(BASE, p)
        if os.path.isfile(full):
            os.remove(full)
        elif os.path.islink(full):
            os.unlink(full)


def write(path, content):
    full = os.path.join(BASE, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w") as f:
        f.write(content)


def sed_replace(path, pattern, replacement):
    full = os.path.join(BASE, path)
    if not os.path.isfile(full):
        return
    with open(full) as f:
        content = f.read()
    content = re.sub(pattern, replacement, content)
    with open(full, "w") as f:
        f.write(content)


DAE_PLACEHOLDER = """\
# 节点配置已移除 — 请添加你自己的节点
# 格式参考: https://github.com/daeuniverse/dae
node {
}
"""


def main():
    # 1. 删除明文代理节点文件和备份
    remove("nodes.dae", "config.dae", "modules/_common/services/dae/nodes.dae")

    # 2. 删除个人日志/录制/临时文件
    remove("nvim.log", "comma", "photorec.se2")

    # 3. 替换 TOML 中的 sleepy token 值
    sed_replace(
        "modules/desktop/hyprland/hypr/pyprland.toml",
        r'token = "ljr811226"',
        'token = "YOUR_SLEEPY_TOKEN"',
    )
    sed_replace(
        "modules/desktop/niri/niri/piri.toml",
        r'token = "ljr811226"',
        'token = "YOUR_SLEEPY_TOKEN"',
    )

    # 4. 创建空的 dae 节点占位文件
    write("modules/_common/services/dae/nodes.dae", DAE_PLACEHOLDER)

    print("清理完成！敏感信息已替换为占位符。")


if __name__ == "__main__":
    main()
