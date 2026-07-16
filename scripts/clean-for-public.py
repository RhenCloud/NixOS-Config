#!/usr/bin/env python3
import os
import re
import shutil

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


OPENCEOD_TEMPLATE = """\
{
  pkgs,
  inputs,
  ...
}:
let
  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    lsp = true;
    model = "voidswitch/claude-opus-4-8";
    small_model = "voidswitch/glm-4.7-flash-cf";
    mcp = {
      chrome-devtools = {
        command = [
          "npx"
          "-y"
          "chrome-devtools-mcp@latest"
          "--executablePath=${pkgs.google-chrome}/bin/google-chrome-stable"
          "--headless=true"
        ];
        type = "local";
      };
      github = {
        enabled = true;
        headers = {
          Authorization = "Bearer YOUR_GITHUB_TOKEN";
        };
        oauth = false;
        type = "remote";
        url = "https://api.githubcopilot.com/mcp/";
      };
      nixos = {
        command = [
          "uvx"
          "mcp-nixos"
        ];
        enabled = true;
        type = "local";
      };
      agent-session-status = {
        enabled = true;
        type = "remote";
        url = "http://127.0.0.1:55854/mcp";
        headers = {
          Authorization = "Bearer YOUR_BEARER_TOKEN";
          X-Agent = "opencode";
        };
      };
    };
    plugin = [
      "${inputs.siiway-oc-plugin.packages.${pkgs.stdenv.hostPlatform.system}.opencode-voidswitch}"
      "opencode-chrome-devtools"
      "@tarquinen/opencode-dcp@latest"
      "@nick-vi/opencode-type-inject"
    ];
    provider = {
      kimi = {
        models = {
          "glm-5.2".name = "";
          "kimi-k2.7-code".name = "";
        };
        npm = "@ai-sdk/openai-compatible";
        options = {
          apiKey = "YOUR_KIMI_API_KEY";
          baseURL = "https://api.0x7e.vip/v1";
          setCacheKey = true;
        };
      };
      me = {
        models = {
          "gpt-5.3-codex".name = "";
          "gpt-5.5".name = "";
        };
        npm = "@ai-sdk/openai-compatible";
        options = {
          apiKey = "YOUR_LOCAL_API_KEY";
          baseURL = "http://127.0.0.1:8080/v1";
          setCacheKey = true;
        };
      };
      sub2api = {
        models = {
          "gpt-5.5".name = "";
        };
        npm = "@ai-sdk/openai-compatible";
        options = {
          apiKey = "YOUR_SUB2API_KEY";
          baseURL = "https://sub2api.wss.moe";
          setCacheKey = true;
        };
      };
      voidswitch = {
        npm = "@ai-sdk/openai-compatible";
        name = "VoidSwitch";
        options = {
          apiKey = "YOUR_VOIDSWITCH_API_KEY";
          baseURL = "https://voidswitch.siiway.org";
        };
        models = {
          "claude-opus-4-8" = { };
          "glm-4.7-flash-cf" = { };
          "deepseek-v4-pro" = { };
          "codex-gpt-5.5" = { };
          "gpt-5.5" = { };
          "claude-sonnet-4-5" = { };
          "grok-4.3-beta" = { };
          "doghubx-gpt-5.5" = { };
        };
      };
    };
  };
in
{
  xdg.configFile = {
    "opencode/opencode.json".text = builtins.toJSON opencodeConfig;
  };
}
"""

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
    write("modules/home/dev/siiway-opencode.nix", OPENCEOD_TEMPLATE)

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
