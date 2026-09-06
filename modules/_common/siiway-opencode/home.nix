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
          "qwen-3.8-max" = { };
          "codex-gpt-5.5" = { };
          "gpt-5.5" = { };
          "claude-sonnet-4-5" = { };
          "grok-4.3-beta" = { };
          "doghubx-gpt-5.5" = { };
          "gpt-5.6-luna" = { };
        };
      };
      voidswitch-openai = {
        npm = "@ai-sdk/openai-compatible";
        name = "VoidSwitch (OpenAI)";
        options = {
          apiKey = config.sops.placeholder."opencode-voidswitch-api-key";
          baseURL = "https://voidswitch.siiway.org/v1";
        };
        models = {
          "deepseek-v4-pro" = { };
          "deepseek-v4-flash" = { };
          "deepseek-v4-flash-0731" = { };
          "qwen-3.8-max" = { };
          "cc/claude-opus-4-8" = { };
          "cc/claude-opus-4-7" = { };
          "cc/claude-opus-4-6" = { };
          "cc/claude-opus-5" = { };
          "cc/claude-sonnet-5" = { };
          "cc/claude-sonnet-4-6" = { };
          "cc/claude-haiku-4-5" = { };
          "cc/claude-fable-5" = { };
          "glm-4.7-flash-cf" = { };
          "glm-4.7" = { };
          "glm-4.5-air" = { };
          "grok-4.5" = { };
          "grok-code-fast-1" = { };
          "kimi-k2.5" = { };
          "mimo-v2.5-pro" = { };
          "minimaxai/minimax-m3" = { };
          "google/gemma-4-31b-it" = { };
        };
      };
      chibang-codex = {
        models = {
          "gpt-5.3-codex" = { };
          "gpt-5.3-codex-spark" = { };
          "gpt-5.4" = { };
          "gpt-5.4-mini" = { };
          "gpt-5.2" = { };
          "gpt-5.5" = { };
          "gpt-5.6-sol" = { };
          "gpt-5.6-terra" = { };
        };
        npm = "@ai-sdk/openai-compatible";
        options = {
          apiKey = config.sops.placeholder."chibang-codex-api-key";
          baseURL = "https://chatapi.transmtf.com/v1";
          setCacheKey = true;
        };
      };
      chibang-claude = {
        models = {
          "claude-opus-4-8" = { };
          "claude-opus-4-7" = { };
          "claude-opus-4-6" = { };
          "claude-sonnet-5" = { };
          "claude-sonnet-4-6" = { };
          "claude-sonnet-4-5-20250929" = { };
          "claude-haiku-4-5-20251001" = { };
        };
        npm = "@ai-sdk/openai-compatible";
        options = {
          apiKey = config.sops.placeholder."chibang-claude-api-key";
          baseURL = "https://chatapi.transmtf.com/v1";
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
      "opencode-voidswitch-api-key" = snowveil.sops.secret {
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
    };

    sops.templates."opencode.json" = {
      content = builtins.toJSON {
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
            headers.Authorization = "Bearer ${config.sops.placeholder."github-token"}";
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
              "qwen-3.8-max" = { };
              "codex-gpt-5.5" = { };
              "gpt-5.5" = { };
              "claude-sonnet-4-5" = { };
              "grok-4.3-beta" = { };
              "doghubx-gpt-5.5" = { };
              "gpt-5.6-luna" = { };
            };
          };
          voidswitch-openai = {
            npm = "@ai-sdk/openai-compatible";
            name = "VoidSwitch (OpenAI)";
            options = {
              apiKey = config.sops.placeholder."opencode-voidswitch-api-key";
              baseURL = "https://voidswitch.siiway.org/v1";
            };
            models = {
              "deepseek-v4-pro" = { };
              "deepseek-v4-flash" = { };
              "deepseek-v4-flash-0731" = { };
              "qwen-3.8-max" = { };
              "cc/claude-opus-4-8" = { };
              "cc/claude-opus-4-7" = { };
              "cc/claude-opus-4-6" = { };
              "cc/claude-opus-5" = { };
              "cc/claude-sonnet-5" = { };
              "cc/claude-sonnet-4-6" = { };
              "cc/claude-haiku-4-5" = { };
              "cc/claude-fable-5" = { };
              "glm-4.7-flash-cf" = { };
              "glm-4.7" = { };
              "glm-4.5-air" = { };
              "grok-4.5" = { };
              "grok-code-fast-1" = { };
              "kimi-k2.5" = { };
              "mimo-v2.5-pro" = { };
              "minimaxai/minimax-m3" = { };
              "google/gemma-4-31b-it" = { };
            };
          };
          chibang-codex = {
            models = {
              "gpt-5.3-codex" = { };
              "gpt-5.3-codex-spark" = { };
              "gpt-5.4" = { };
              "gpt-5.4-mini" = { };
              "gpt-5.2" = { };
              "gpt-5.5" = { };
              "gpt-5.6-sol" = { };
              "gpt-5.6-terra" = { };
            };
            npm = "@ai-sdk/openai-compatible";
            options = {
              apiKey = config.sops.placeholder."chibang-codex-api-key";
              baseURL = "https://chatapi.transmtf.com/v1";
              setCacheKey = true;
            };
          };
          chibang-claude = {
            models = {
              "claude-opus-4-8" = { };
              "claude-opus-4-7" = { };
              "claude-opus-4-6" = { };
              "claude-sonnet-5" = { };
              "claude-sonnet-4-6" = { };
              "claude-sonnet-4-5-20250929" = { };
              "claude-haiku-4-5-20251001" = { };
            };
            npm = "@ai-sdk/openai-compatible";
            options = {
              apiKey = config.sops.placeholder."chibang-claude-api-key";
              baseURL = "https://chatapi.transmtf.com/v1";
            };
          };
        };
      };
    };

    xdg.configFile."opencode/opencode.json".source =
      config.lib.file.mkOutOfStoreSymlink
        config.sops.templates."opencode.json".path;

    xdg.configFile."opencode/plugins/chibang-claude.ts".text = ''
      const clean = (value) => {
        if (Array.isArray(value)) return value.map(clean)
        if (!value || typeof value !== "object") return value

        return Object.fromEntries(
          Object.entries(value)
            .filter(([key]) => key !== "cache_control")
            .map(([key, item]) => [key, clean(item)]),
        )
      }

      export default async () => ({
        config(config) {
          const provider = config.provider?.["chibang-claude"]
          if (!provider) return

          provider.options ??= {}
          provider.options.fetch = async (input, init) => {
            if (typeof init?.body === "string") {
              try {
                const body = clean(JSON.parse(init.body))
                delete body.stream_options
                if (Array.isArray(body.messages)) {
                  const system = body.messages.filter((message) => message.role === "system")
                  body.messages = body.messages.filter((message) => message.role !== "system")
                  if (system.length > 0) {
                    body.system = system.flatMap((message) =>
                      typeof message.content === "string"
                        ? [{ type: "text", text: message.content }]
                        : message.content,
                    )
                  }
                }
                if (Array.isArray(body.tools)) {
                  body.tools = body.tools.map((tool) =>
                    tool.type === "function"
                      ? {
                          type: "custom",
                          name: tool.function.name,
                          description: tool.function.description,
                          input_schema: tool.function.parameters,
                        }
                      : tool,
                  )
                }
                if (typeof body.tool_choice === "string") {
                  if (body.tool_choice === "none") {
                    delete body.tool_choice
                    delete body.tools
                  } else {
                    body.tool_choice = {
                      type: body.tool_choice === "required" ? "any" : body.tool_choice,
                    }
                  }
                } else if (body.tool_choice?.type === "function") {
                  body.tool_choice = {
                    type: "tool",
                    name: body.tool_choice.function.name,
                  }
                }
                init = { ...init, body: JSON.stringify(body) }
              } catch {}
            }

            return fetch(input, init)
          }
        },
      })
    '';
  };
}
