#!/usr/bin/env python3
import os
import re
import shutil

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SECRET_MAP = {
    # siiway-opencode.nix 中的秘密值 → 占位符
    "REDACTED-9ec4148f": "YOUR_GITHUB_TOKEN",
    "81cd0b3f83bfacf53bb0c61dad0cc04d3d6bdca850b66de80d0a22def1c858b8": "YOUR_BEARER_TOKEN",
    "sk-QbvDLExF4SMtp3uFvqOkJObcL6rg90DoqEgnxXof95PPJ2Ye": "YOUR_KIMI_API_KEY",
    "REDACTED-b73a34f8": "YOUR_LOCAL_API_KEY",
    "REDACTED-bc0db852": "YOUR_SUB2API_KEY",
    "REDACTED-71bdd162": "YOUR_VOIDSWITCH_API_KEY",
    "REDACTED-5fcc9ef0": "YOUR_OPENCODE_API_KEY",
}


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
    remove("nodes.dae", "config.dae", "modules/nixos/core/dae/nodes.dae")

    # 2. 删除个人日志/录制/临时文件
    remove("nvim.log", "comma", "photorec.se2")

    # 3. 替换 opencode 配置中的 API 密钥和令牌
    for secret, placeholder in SECRET_MAP.items():
        sed_replace(
            "modules/home/dev/siiway-opencode.nix",
            re.escape(secret),
            placeholder,
        )

    # 4. 替换 TOML 中的 sleepy token 值
    sed_replace(
        "modules/home/desktop/hyprland/hypr/pyprland.toml",
        r'token = "ljr811226"',
        'token = "YOUR_SLEEPY_TOKEN"',
    )
    sed_replace(
        "modules/home/desktop/niri/niri/piri.toml",
        r'token = "ljr811226"',
        'token = "YOUR_SLEEPY_TOKEN"',
    )

    # 5. 创建空的 dae 节点占位文件
    write("modules/nixos/core/dae/nodes.dae", DAE_PLACEHOLDER)

    print("清理完成！敏感信息已替换为占位符。")


if __name__ == "__main__":
    main()
