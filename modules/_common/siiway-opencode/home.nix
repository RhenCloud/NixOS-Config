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
        enabled = true;
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
      logoloom = {
        command = [
          "npx"
          "-y"
          "@mcpware/logoloom"
        ];
        enabled = true;
        type = "local";
      };
    };
    plugin = [
      "${voidswitchPlugin}"
      "opencode-antigravity-auth@latest"
      "opencode-chrome-devtools"
      "@tarquinen/opencode-dcp@latest"
      "@nick-vi/opencode-type-inject"
      "opencode-pty"
      "remote-code"
    ]
    ++ optional cfg.wakatime.enable "opencode-wakatime";
    provider = {
      voidswitch = {
        npm = "@ai-sdk/openai-compatible";
        name = "VoidSwitch";
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
          "codex/gpt-5.6-terra" = { };
          "glm-4.7-flash-cf" = { };
          "murasame-vip/gemini-3.8-flash-high" = { };
          # "glm-4.7" = { };
          # "glm-4.5-air" = { };
          # "grok-4.5" = { };
          # "grok-code-fast-1" = { };
          "kimi-k2.5" = { };
          "mimo-v2.5-pro" = { };
          # "minimaxai/minimax-m3" = { };
          # "google/gemma-4-31b-it" = { };
          # "gpt-5.6-sol" = { };
          # "gpt-5.6-terra" = { };
        };
      };
      chibang-codex = {
        models = {
          # "gpt-5.3-codex" = { };
          # "gpt-5.3-codex-spark" = { };
          # "gpt-5.4" = { };
          # "gpt-5.4-mini" = { };
          # "gpt-5.2" = { };
          # "gpt-5.5" = { };
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
      google = {
        npm = "@ai-sdk/google";
        models = {
          "antigravity-gemini-3-pro" = {
            name = "Gemini 3 Pro (Antigravity)";
            limit = {
              context = 1048576;
              output = 65535;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
            variants = {
              low = {
                thinkingLevel = "low";
              };
              high = {
                thinkingLevel = "high";
              };
            };
          };
          "antigravity-gemini-3.1-pro" = {
            name = "Gemini 3.1 Pro (Antigravity)";
            limit = {
              context = 1048576;
              output = 65535;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
            variants = {
              low = {
                thinkingLevel = "low";
              };
              high = {
                thinkingLevel = "high";
              };
            };
          };
          "antigravity-gemini-3-flash" = {
            name = "Gemini 3 Flash (Antigravity)";
            limit = {
              context = 1048576;
              output = 65536;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
            variants = {
              minimal = {
                thinkingLevel = "minimal";
              };
              low = {
                thinkingLevel = "low";
              };
              medium = {
                thinkingLevel = "medium";
              };
              high = {
                thinkingLevel = "high";
              };
            };
          };
          "antigravity-claude-sonnet-4-6" = {
            name = "Claude Sonnet 4.6 (Antigravity)";
            limit = {
              context = 200000;
              output = 64000;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
          };
          "antigravity-claude-opus-4-6-thinking" = {
            name = "Claude Opus 4.6 Thinking (Antigravity)";
            limit = {
              context = 200000;
              output = 64000;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
            variants = {
              low = {
                thinkingConfig = {
                  thinkingBudget = 8192;
                };
              };
              max = {
                thinkingConfig = {
                  thinkingBudget = 32768;
                };
              };
            };
          };
          "gemini-2.5-flash" = {
            name = "Gemini 2.5 Flash (Gemini CLI)";
            limit = {
              context = 1048576;
              output = 65536;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
          };
          "gemini-2.5-pro" = {
            name = "Gemini 2.5 Pro (Gemini CLI)";
            limit = {
              context = 1048576;
              output = 65536;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
          };
          "gemini-3-flash-preview" = {
            name = "Gemini 3 Flash Preview (Gemini CLI)";
            limit = {
              context = 1048576;
              output = 65536;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
          };
          "gemini-3-pro-preview" = {
            name = "Gemini 3 Pro Preview (Gemini CLI)";
            limit = {
              context = 1048576;
              output = 65535;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
          };
          "gemini-3.1-pro-preview" = {
            name = "Gemini 3.1 Pro Preview (Gemini CLI)";
            limit = {
              context = 1048576;
              output = 65535;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
          };
          "gemini-3.1-pro-preview-customtools" = {
            name = "Gemini 3.1 Pro Preview Custom Tools (Gemini CLI)";
            limit = {
              context = 1048576;
              output = 65535;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
          };
        };
      };
    };
  };
in
{
  options = {
    rhencloud.opencode.enable = mkEnableOption "opencode AI assistant";
    rhencloud.opencode.wakatime.enable = mkEnableOption "opencode WakaTime/HackaTime 时间追踪";
  };
  config = mkMerge [
    (mkIf cfg.enable {
      programs.opencode = {
        enable = true;
        # package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.opencode-zh-cn;
      };

      sops.secrets = {
        "github-token" = snowveil.sops.secret { source = "common"; };
        "opencode-voidswitch-api-key" = snowveil.sops.secret { source = "common"; };
        "chibang-codex-api-key" = snowveil.sops.secret { source = "common"; };
        "chibang-claude-api-key" = snowveil.sops.secret { source = "common"; };
      };

      sops.templates."opencode.json".content = builtins.toJSON opencodeConfig;

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
    })
    (mkIf cfg.wakatime.enable {
      sops.secrets."wakatime-api-key" = snowveil.sops.secret { source = "common"; };

      # HackaTime（WakaTime 兼容），通过 opencode-wakatime 插件上报
      sops.templates."wakatime.cfg".content = ''
        [settings]
        api_key = ${config.sops.placeholder."wakatime-api-key"}
        api_url = https://hackatime.hackclub.com/api/hackatime/v1
      '';

      home.file.".wakatime.cfg".source =
        config.lib.file.mkOutOfStoreSymlink
          config.sops.templates."wakatime.cfg".path;

      home.packages = [ pkgs.wakatime-cli ];
    })
  ];
}
