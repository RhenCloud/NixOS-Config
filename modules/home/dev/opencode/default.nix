{
  lib,
  pkgs,
  ...
}:
let
  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    lsp = true;
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
          Authorization = "Bearer REDACTED-9ec4148f";
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
    plugin = [ "oh-my-openagent@latest" ];
    provider = {
      kimi = {
        models = {
          "glm-5.2".name = "";
          "kimi-k2.7-code".name = "";
        };
        npm = "@ai-sdk/openai-compatible";
        options = {
          apiKey = "sk-QbvDLExF4SMtp3uFvqOkJObcL6rg90DoqEgnxXof95PPJ2Ye";
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
          apiKey = "REDACTED-b73a34f8";
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
          apiKey = "REDACTED-bc0db852";
          baseURL = "https://sub2api.wss.moe";
          setCacheKey = true;
        };
      };
      voidswitch = {
        models = {
          "claude-opus-4-6".name = "";
          "deepseek-v4-pro".name = "";
          "deepseek-v4-pro-lkd".name = "";
          "glm-4.7-flash-cf".name = "";
          "gpt-5.5".name = "";
          "kimi-k2.7-code".name = "";
          "mimo-v2.5-pro".name = "";
          "qwen3.7-plus".name = "";
        };
        npm = "@ai-sdk/openai-compatible";
        options = {
          apiKey = "REDACTED-ad0dc1d9";
          baseURL = "https://voidswitch.siiway.org/v1";
          setCacheKey = true;
        };
      };
    };
  };

  ohMyOpenagentConfig = {
    agents = {
      atlas.model = "voidswitch/glm-4.7-flash-cf";
      hephaestus.model = "voidswitch/claude-opus-4-6";
      oracle.model = "voidswitch/claude-opus-4-6";
      prometheus.model = "voidswitch/glm-4.7-flash-cf";
      sisyphus.model = "voidswitch/claude-opus-4-6";
    };
    categories = {
      "visual-engineering".model = "voidswitch/claude-opus-4-6";
    };
  };
in
{
  xdg.configFile = {
    "opencode/opencode.json".text = builtins.toJSON opencodeConfig;
    "opencode/oh-my-openagent.jsonc".text = builtins.toJSON ohMyOpenagentConfig;

    "opencode/AGENTS.md" = {
      source = ./AGENTS.md;
      force = true;
    };

    "opencode/skills/code-review-skill/SKILL.md".source = ./skills/code-review-skill/SKILL.md;
    "opencode/skills/frontend-design/SKILL.md".source = ./skills/frontend-design/SKILL.md;
    "opencode/skills/frontend-design/LICENSE.txt".source = ./skills/frontend-design/LICENSE.txt;
    "opencode/skills/nix-flakes-env/SKILL.md".source = ./skills/nix-flakes-env/SKILL.md;
  };
}
