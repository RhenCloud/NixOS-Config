{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  inherit (lib.strings) trim;
  readSecret = path: trim (builtins.readFile "${inputs.self}/secrets/${path}");

  githubToken = readSecret "opencode/github-token";
  frimodelApiKey = readSecret "opencode/frimodel-api-key";
  localApiKey = readSecret "opencode/local-api-key";
  sub2apiKey = readSecret "opencode/sub2api-key";
  voidswitchApiKey = readSecret "opencode/voidswitch-api-key";
  zhiApiKey = readSecret "opencode/zhi-api-key";

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
          Authorization = "Bearer ${githubToken}";
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
    };
    plugin = [
      "${inputs.siiway-oc-plugin.packages.${pkgs.stdenv.hostPlatform.system}.opencode-voidswitch}"
      "opencode-chrome-devtools"
      "@tarquinen/opencode-dcp@latest"
      "@nick-vi/opencode-type-inject"
    ];
    provider = {
      FriModel = {
        models = {
          "gpt-5.4".name = "";
        };
        npm = "@ai-sdk/openai-compatible";
        options = {
          apiKey = "${frimodelApiKey}";
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
          apiKey = "${localApiKey}";
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
          apiKey = "${sub2apiKey}";
          baseURL = "https://sub2api.wss.moe";
          setCacheKey = true;
        };
      };
      voidswitch = {
        npm = "@ai-sdk/anthropic";
        name = "VoidSwitch";
        options = {
          apiKey = "${voidswitchApiKey}";
          baseURL = "https://voidswitch.siiway.org/v1";
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
      zhi = {
        models = {
          "qwen3.7-max".name = "";
        };
        npm = "@ai-sdk/openai-compatible";
        options = {
          apiKey = "${zhiApiKey}";
          baseURL = "https://zhi-api.com/v1";
          setCacheKey = true;
        };
      };
    };
  };
in
with lib;
let
  cfg = config.rhencloud.opencode;
in {
  options.rhencloud.opencode.enable = mkEnableOption "opencode AI assistant";
  config = mkIf cfg.enable {
    xdg.configFile = {
    "opencode/opencode.json".text = builtins.toJSON opencodeConfig;
  };
  };
}
