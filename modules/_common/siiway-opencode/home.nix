{
  config,
  lib,
  pkgs,
  inputs,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhencloud.opencode;
  system = pkgs.stdenv.hostPlatform.system;
  voidswitchPlugin =
    inputs.siiway-oc-plugin.packages.${system}.opencode-voidswitch.overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [
          ../../../patches/opencode-voidswitch/plugin-default-export.patch
        ];
      });
  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    model = "voidswitch/deepseek-v4-pro";
    small_model = "voidswitch/glm-4.7-flash-cf";
    lsp = true;
    mcp = {
      chrome-devtools = {
        enabled = false;
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
          Authorization = "Bearer ${config.sops.placeholder."github-token"}";
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
      playwright = {
        command = [
          "npx"
          "-y"
          "@playwright/mcp@latest"
          "--browser"
          "chromium"
          "--executable-path"
          "${pkgs.chromium}/bin/chromium"
          "--headless"
        ];
        enabled = true;
        type = "local";
      };
    };
    plugin = [
      "${voidswitchPlugin}"
      "opencode-chrome-devtools"
      "@tarquinen/opencode-dcp@latest"
      "@nick-vi/opencode-type-inject"
      "remote-code"
    ];
    provider = {
      FriModel = {
        models = {
          "gpt-5.4".name = "";
        };
        npm = "@ai-sdk/openai-compatible";
        options = {
          apiKey = config.sops.placeholder."opencode-frimodel-api-key";
          baseURL = "https://api.frimodel.com/v1";
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
          apiKey = config.sops.placeholder."opencode-local-api-key";
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
          apiKey = config.sops.placeholder."opencode-sub2api-key";
          baseURL = "https://sub2api.wss.moe";
          setCacheKey = true;
        };
      };
      voidswitch = {
        npm = "@ai-sdk/anthropic";
        name = "VoidSwitch";
        options = {
          apiKey = config.sops.placeholder."opencode-voidswitch-api-key";
          baseURL = "https://voidswitch.siiway.org/v1";
        };
        models = {
          "claude-opus-4-8" = { };
          "glm-4.7-flash-cf" = { };
          "deepseek-v4-pro" = { };
          "deepseek-v4-flash" = { };
          "codex-gpt-5.5" = { };
          "gpt-5.5" = { };
          "claude-sonnet-4-5" = { };
          "grok-4.3-beta" = { };
          "doghubx-gpt-5.5" = { };
          "gpt-5.6-luna" = { };
        };
      };
      zhi = {
        models = {
          "qwen3.7-max".name = "";
        };
        npm = "@ai-sdk/openai-compatible";
        options = {
          apiKey = config.sops.placeholder."opencode-zhi-api-key";
          baseURL = "https://zhi-api.com/v1";
          setCacheKey = true;
        };
      };
    };
  };
in
{
  options.rhencloud.opencode.enable = mkEnableOption "opencode AI assistant";
  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      # package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.opencode-zh-cn;
    };

    sops.secrets = {
      "github-token" = snowveil.sops.secret { source = "common"; };
      "opencode-frimodel-api-key" = snowveil.sops.secret {
        source = "host";
        host = "nixos-desktop";
      };
      "opencode-local-api-key" = snowveil.sops.secret {
        source = "host";
        host = "nixos-desktop";
      };
      "opencode-sub2api-key" = snowveil.sops.secret {
        source = "host";
        host = "nixos-desktop";
      };
      "opencode-voidswitch-api-key" = snowveil.sops.secret {
        source = "host";
        host = "nixos-desktop";
      };
      "opencode-zhi-api-key" = snowveil.sops.secret {
        source = "host";
        host = "nixos-desktop";
      };
    };

    sops.templates."opencode.json" = {
      content = builtins.toJSON opencodeConfig;
    };

    xdg.configFile."opencode/opencode.json".source =
      config.lib.file.mkOutOfStoreSymlink
        config.sops.templates."opencode.json".path;
  };
}
