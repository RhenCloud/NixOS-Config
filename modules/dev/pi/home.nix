{
  config,
  lib,
  pkgs,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhencloud.pi;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      pi-coding-agent
      rtk
    ];

    sops.secrets = {
      "opencode-voidswitch-api-key" = snowveil.sops.secret {
        source = "host";
        host = "nixos-desktop";
      };
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
      "opencode-zhi-api-key" = snowveil.sops.secret {
        source = "host";
        host = "nixos-desktop";
      };
      "chibang-codex-api-key" = snowveil.sops.secret {
        source = "host";
        host = "nixos-desktop";
      };
      "chibang-claude-api-key" = snowveil.sops.secret {
        source = "host";
        host = "nixos-desktop";
      };
      "github-token" = snowveil.sops.secret { source = "common"; };
    };

    sops.templates."pi/models.json" = {
      mode = "0400";
      content = ''
        {
          "providers": {
            "voidswitch": {
              "baseUrl": "https://voidswitch.siiway.org/v1",
              "api": "openai-completions",
              "apiKey": "${config.sops.placeholder."opencode-voidswitch-api-key"}",
              "headers": { "User-Agent": "pi/0.84.2" },
              "models": [
                { "id": "deepseek-v4-pro", "name": "DeepSeek V4 Pro", "reasoning": true },
                { "id": "qwen-3.8-max", "name": "Qwen 3.8 Max", "reasoning": true },
                { "id": "deepseek-v4-flash", "name": "DeepSeek V4 Flash", "reasoning": true },
                { "id": "cc/claude-opus-4-7", "name": "Claude Opus 4.7", "reasoning": true },
                { "id": "cc/claude-sonnet-4-6", "name": "Claude Sonnet 4.6", "reasoning": true },
                { "id": "cc/claude-haiku-4.5", "name": "Claude Haiku 4.5", "reasoning": true },
                { "id": "glm-4.7-flash-cf", "name": "GLM 4.7 Flash CF" },
                { "id": "codex-gpt-5.5", "name": "Codex GPT-5.5" },
                { "id": "gpt-5.5", "name": "GPT-5.5" },
                { "id": "gpt-5.6-luna", "name": "GPT-5.6 Luna" },
                { "id": "grok-4.3-beta", "name": "Grok 4.3 Beta" },
                { "id": "doghubx-gpt-5.5", "name": "DogHubX GPT-5.5" }
              ]
            },
            "chibang-codex": {
              "baseUrl": "https://chatapi.transmtf.com/v1",
              "api": "openai-completions",
              "apiKey": "${config.sops.placeholder."chibang-codex-api-key"}",
              "models": [
                { "id": "gpt-5.3-codex", "name": "GPT-5.3 Codex", "reasoning": true },
                { "id": "gpt-5.3-codex-spark", "name": "GPT-5.3 Codex Spark" },
                { "id": "gpt-5.4", "name": "GPT-5.4" },
                { "id": "gpt-5.4-mini", "name": "GPT-5.4 Mini" },
                { "id": "gpt-5.2", "name": "GPT-5.2" },
                { "id": "gpt-5.5", "name": "GPT-5.5" },
                { "id": "gpt-5.6-sol", "name": "GPT-5.6 Sol" },
                { "id": "gpt-5.6-terra", "name": "GPT-5.6 Terra" }
              ]
            },
            "chibang-claude": {
              "baseUrl": "https://chatapi.transmtf.com",
              "api": "anthropic-messages",
              "apiKey": "${config.sops.placeholder."chibang-claude-api-key"}",
              "models": [
                { "id": "claude-opus-4-8", "name": "Claude Opus 4.8", "reasoning": true },
                { "id": "claude-opus-4-7", "name": "Claude Opus 4.7", "reasoning": true },
                { "id": "claude-opus-4-6", "name": "Claude Opus 4.6", "reasoning": true },
                { "id": "claude-sonnet-5", "name": "Claude Sonnet 5", "reasoning": true },
                { "id": "claude-sonnet-4-6", "name": "Claude Sonnet 4.6" },
                { "id": "claude-sonnet-4-5-20250929", "name": "Claude Sonnet 4.5" },
                { "id": "claude-haiku-4-5-20251001", "name": "Claude Haiku 4.5" }
              ]
            }
          }
        }
      '';
    };

    sops.templates."pi/mcp.json" = {
      mode = "0400";
      content = builtins.toJSON {
        settings = {
          hostConfigDiscovery = "off";
        };
        mcpServers = {
          chrome-devtools = {
            command = "bunx";
            args = [
              "-y"
              "chrome-devtools-mcp@latest"
              "--executablePath=${pkgs.google-chrome}/bin/google-chrome-stable"
              "--headless=true"
            ];
            disabled = true;
          };
          github = {
            url = "https://api.githubcopilot.com/mcp/";
            headers.Authorization = "Bearer ${config.sops.placeholder."github-token"}";
            oauth = false;
          };
          nixos = {
            command = "uvx";
            args = [ "mcp-nixos" ];
          };
          playwright = {
            command = "npx";
            args = [
              "-y"
              "@playwright/mcp@latest"
              "--browser"
              "chromium"
              "--executable-path"
              "${pkgs.chromium}/bin/chromium"
              "--headless"
            ];
          };
        };
      };
    };

    home.file.".pi/agent/models.json".source =
      config.lib.file.mkOutOfStoreSymlink
        config.sops.templates."pi/models.json".path;

    home.file.".pi/agent/mcp.json".source =
      config.lib.file.mkOutOfStoreSymlink
        config.sops.templates."pi/mcp.json".path;

    home.file.".pi/agent/themes/dracula.json".source = ./themes/dracula.json;

    home.file.".pi/agent/settings.json".text = builtins.toJSON {
      defaultProvider = cfg.defaultProvider;
      defaultModel = "deepseek-v4-pro";
      theme = cfg.theme;
      packages = [
        "npm:pi-mcp-adapter"
        "npm:pi-subagents"
        "npm:pi-web-access"
        "npm:@plannotator/pi-extension"
        "npm:@juicesharp/rpiv-todo"
        "git:github.com/dafei1288/pi-agent-hud"
        "git:github.com/MasuRii/pi-rtk-optimizer"
        "npm:@ogulcancelik/pi-herdr"
        "npm:@ff-labs/pi-fff"
        "git:github.com/tianrendong/pi-loadout"
      ];
    };
  };
}
