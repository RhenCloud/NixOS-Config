{
  config,
  lib,
  pkgs,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhen.pi;

  # 各 provider 对应的推荐默认模型
  providerDefaultModels = {
    "voidswitch" = "deepseek-v4.1-flash";
    "chibang-claude" = "claude-opus-5-5";
    "chibang-codex" = "gpt-5.6-terra";
    "chibang-cn" = "glm-5.3-flash";
  };

  effectiveDefaultModel =
    if cfg.defaultModel != null then
      cfg.defaultModel
    else
      providerDefaultModels.${cfg.defaultProvider} or "ds-7031";
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      pi-coding-agent
      rtk
      bubblewrap
      socat
      wakatime-cli
    ];

    sops.secrets = {
      "opencode-voidswitch-api-key" = snowveil.sops.secret { source = "common"; };
      "chibang-codex-api-key" = snowveil.sops.secret { source = "common"; };
      "chibang-claude-api-key" = snowveil.sops.secret { source = "common"; };
      "chibang-cn-api-key" = snowveil.sops.secret { source = "common"; };
      "github-token" = snowveil.sops.secret { source = "common"; };
      "idcjk-api-key" = snowveil.sops.secret { source = "common"; };
    };

    home.file.".pi/agent/APPEND_SYSTEM.md".source = ./APPEND_SYSTEM.md;

    sops.templates."pi/models.json" = {
      mode = "0400";
      content = ''
        {
          "providers": {
            "voidswitch": {
              "baseUrl": "https://voidswitch.mfawa.top/v1",
              "api": "openai-completions",
              "apiKey": "${config.sops.placeholder."opencode-voidswitch-api-key"}",
              "headers": { "User-Agent": "pi/${pkgs.pi-coding-agent.version}" },
              "models": [
                { "id": "deepseek-v4-pro", "name": "DeepSeek V4 Pro", "reasoning": true },
                { "id": "deepseek-v4-flash-0731", "name": "DeepSeek V4 Flash 0731", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "deepseek-v4-flash", "name": "DeepSeek V4 Flash", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "deepseek-v4.1-flash", "name": "DeepSeek V4.1 Flash", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "codex/gpt-5.6-sol", "name": "GPT 5.6 Sol", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "codex/gpt-5.6-terra", "name": "GPT 5.6 Terra", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "codex/gpt-5.6-luna", "name": "GPT 5.6 Luna", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "codex/gpt-6-astra", "name": "GPT 6 Astra", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "glm-4.7-flash-cf", "name": "GLM 4.7 Flash CF", "input": [ "text", "image" ] },
                { "id": "codex-gpt-5.5", "name": "Codex GPT-5.5", "input": [ "text", "image" ] },
                { "id": "gpt-5.5", "name": "GPT-5.5", "input": [ "text", "image" ] },
                { "id": "gpt-5.6-luna", "name": "GPT-5.6 Luna", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "grok-4.3-beta", "name": "Grok 4.3 Beta", "input": [ "text", "image" ] },
                { "id": "doghubx-gpt-5.5", "name": "DogHubX GPT-5.5", "input": [ "text", "image" ] },
                { "id": "murasame-vip/gemini-3.8-flash-high", "name": "Gemini 3.8 Flash High", "input": [ "text", "image" ] },
                { "id": "oc-zen/mimo-v2.5-free", "name": "MiMo v2.5 Free", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "oc-zen/mimo-v2.6-flash-free", "name": "MiMo v2.6 Flash Free", "reasoning": true, "input": [ "text", "image" ] }
              ]
            },
            "chibang-cn": {
              "baseUrl": "https://ai-api.transcircle.org/v1",
              "api": "openai-completions",
              "apiKey": "${config.sops.placeholder."chibang-cn-api-key"}",
              "models": [
                { "id": "glm-5.3-flash", "name": "GLM 5.3 Flash", "input": [ "text", "image" ] },
                { "id": "deepseek-v4.1-flash-1017", "name": "DeepSeek V4.1 Flash 1017", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "deepseek-v4.1-flash", "name": "DeepSeek V4.1 Flash", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "minimax-m3", "name": "MiniMax M3", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "qwen3.7-plus", "name": "Qwen 3.7 Plus", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "deepseek-v4-pro", "name": "DeepSeek V4 Pro", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "glm-5.3", "name": "GLM 5.3", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "qwen3.8-max", "name": "Qwen 3.8 Max", "reasoning": true, "input": [ "text", "image" ] }
              ]
            },
            "chibang-codex": {
              "baseUrl": "https://chatapi.transmtf.com/v1",
              "api": "openai-completions",
              "apiKey": "${config.sops.placeholder."chibang-codex-api-key"}",
              "models": [
                { "id": "gpt-5.3-codex", "name": "GPT-5.3 Codex", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "gpt-5.3-codex-spark", "name": "GPT-5.3 Codex Spark", "input": [ "text", "image" ] },
                { "id": "gpt-5.4", "name": "GPT-5.4", "input": [ "text", "image" ] },
                { "id": "gpt-5.4-mini", "name": "GPT-5.4 Mini", "input": [ "text", "image" ] },
                { "id": "gpt-5.2", "name": "GPT-5.2", "input": [ "text", "image" ] },
                { "id": "gpt-5.5", "name": "GPT-5.5", "input": [ "text", "image" ] },
                { "id": "gpt-5.6-sol", "name": "GPT-5.6 Sol", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "gpt-5.6-luna", "name": "GPT-5.6 Luna", "reasoning": true, "input": [ "text", "image" ] },
                { "id": "gpt-5.6-terra", "name": "GPT-5.6 Terra", "reasoning": true, "input": [ "text", "image" ] }
              ]
            },
            "chibang-claude": {
              "baseUrl": "https://chatapi.transmtf.com",
              "api": "anthropic-messages",
              "apiKey": "${config.sops.placeholder."chibang-claude-api-key"}",
              "models": [
                {
                  "id": "claude-opus-4-8",
                  "name": "Claude Opus 4.8",
                  "reasoning": true,
                  "input": [ "text", "image" ],
                  "promptCache": { "short": 300, "long": 3600 }
                },
                {
                  "id": "claude-opus-4-7",
                  "name": "Claude Opus 4.7",
                  "reasoning": true,
                  "input": [ "text", "image" ],
                  "promptCache": { "short": 300, "long": 3600 }
                },
                {
                  "id": "claude-opus-4-6",
                  "name": "Claude Opus 4.6",
                  "reasoning": true,
                  "input": [ "text", "image" ],
                  "promptCache": { "short": 300, "long": 3600 }
                },
                {
                  "id": "claude-opus-5-5",
                  "name": "Claude Opus 5.5",
                  "reasoning": true,
                  "input": [ "text", "image" ],
                  "promptCache": { "short": 300, "long": 3600 }
                },
                {
                  "id": "claude-sonnet-5",
                  "name": "Claude Sonnet 5",
                  "reasoning": true,
                  "input": [ "text", "image" ],
                  "promptCache": { "short": 300, "long": 3600 }
                },
                {
                  "id": "claude-sonnet-4-6",
                  "name": "Claude Sonnet 4.6",
                  "input": [ "text", "image" ],
                  "promptCache": { "short": 300, "long": 3600 }
                },
                {
                  "id": "claude-sonnet-4-5-20250929",
                  "name": "Claude Sonnet 4.5",
                  "input": [ "text", "image" ],
                  "promptCache": { "short": 300, "long": 3600 }
                },
                {
                  "id": "claude-haiku-4-5-20251001",
                  "name": "Claude Haiku 4.5",
                  "input": [ "text", "image" ],
                  "promptCache": { "short": 300, "long": 3600 }
                }
              ]
            }
          }
        }
      '';
    };

    sops.templates."pi/mcp-adapter.json" = {
      mode = "0400";
      content = builtins.toJSON {
        settings = {
          hostConfigDiscovery = "off";
        };
        mcpServers = {
          chrome-devtools = {
            command = "npx";
            args = [
              "-y"
              "chrome-devtools-mcp@latest"
              "--executablePath=${pkgs.google-chrome}/bin/google-chrome-stable"
              "--headless=true"
            ];
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
          logoloom = {
            command = "npx";
            args = [
              "-y"
              "@mcpware/logoloom"
            ];
          };
          idcjk = {
            url = "https://api.idcjk.com/api/v1/mcp";
            headers.Authorization = "Bearer ${config.sops.placeholder."idcjk-api-key"}";
          };
        };
      };
    };

    home.file.".pi/agent/models.json".source =
      config.lib.file.mkOutOfStoreSymlink
        config.sops.templates."pi/models.json".path;

    home.file.".pi/agent/mcp-adapter.json".source =
      config.lib.file.mkOutOfStoreSymlink
        config.sops.templates."pi/mcp-adapter.json".path;

    home.file.".pi/agent/themes/dracula.json".source = ./themes/dracula.json;

    home.file.".pi/agent/pi-btw.json".text = builtins.toJSON {
      layout = "left-pane";
      sidePaneRatio = 0.4;
      thinkingLevel = "low";
      rememberThinkingLevelChanges = true;
      fullscreenCopyOnSelect = true;
    };

    home.file.".pi/agent/permission-mode/permission-mode.json".text = builtins.toJSON {
      "$schema" =
        "https://raw.githubusercontent.com/wynainfo/pi-permission-modes/main/schemas/permission-mode.schema.json";
      defaultMode = "auto";
      cycleOrder = [
        # "plan"
        # "build"
        "auto"
      ];
      modes = {
        # plan = {
        #   label = "Plan";
        #   color = "mdLink";
        #   permission = {
        #     path = {
        #       "*" = "allow";
        #       "*.env" = "deny";
        #       "*.env.*" = "deny";
        #     };
        #     external_directory = "allow";
        #     read = "allow";
        #     grep = "allow";
        #     find = "allow";
        #     ls = "allow";
        #     write = "deny";
        #     edit = "deny";
        #     bash = {
        #       "*" = "deny";
        #     };
        #     web_search = "allow";
        #     tool = "allow";
        #     skill = "allow";
        #   };
        #   sandbox = {
        #     writable = false;
        #   };
        #   hideTools = [ ];
        # };
        # build = {
        #   label = "Build";
        #   color = "accent";
        #   permission = {
        #     path = {
        #       "*" = "allow";
        #       "*.env" = "deny";
        #       "*.env.*" = "deny";
        #     };
        #     external_directory = "allow";
        #     read = "allow";
        #     grep = "allow";
        #     find = "allow";
        #     ls = "allow";
        #     write = "allow";
        #     edit = "allow";
        #     bash = {
        #       "*" = "allow";
        #     };
        #     web_search = "allow";
        #     tool = "allow";
        #     skill = "allow";
        #   };
        #   sandbox = {
        #     writable = true;
        #   };
        #   hideTools = [ ];
        # };
        auto = {
          label = "Auto";
          color = "error";
          bypassProtectedPaths = true;
          permission = {
            path = "allow";
            external_directory = "allow";
            read = "allow";
            grep = "allow";
            find = "allow";
            ls = "allow";
            write = "allow";
            edit = "allow";
            bash = "allow";
            web_search = "allow";
            tool = "allow";
            skill = "allow";
          };
          sandbox = {
            enabled = false;
            writable = true;
          };
          hideTools = [ ];
        };
      };
    };

    home.file.".pi/agent/settings.json".text = builtins.toJSON {
      defaultProvider = cfg.defaultProvider;
      defaultModel = effectiveDefaultModel;
      theme = cfg.theme;
      enableInstallTelemetry = false;
      enableAnalytics = false;
      extensions = [
        "-builtin:mcp"
      ];
      modelThinkingLevels = {
        "voidswitch/deepseek-v4-flash" = "low";
        "voidswitch/glm-4.7-flash-cf" = "low";
        "voidswitch/cc/claude-haiku-4-5" = "low";
        "chibang-codex/gpt-5.4-mini" = "low";
        "chibang-claude/claude-haiku-4-5-20251001" = "low";
      };
      packages = [
        "npm:pi-mcp-adapter"
        "npm:pi-subagents"
        "npm:pi-web-access"
        "npm:pi-zentui"
        "npm:pi-permission-modes"
        "npm:@plannotator/pi-extension"
        "npm:@juicesharp/rpiv-todo"
        "git:github.com/MasuRii/pi-rtk-optimizer"
        "npm:@ogulcancelik/pi-herdr"
        "npm:@ff-labs/pi-fff"
        "git:github.com/tianrendong/pi-loadout"
        "npm:pi-lens@^4.3.0"
        "npm:@juicesharp/rpiv-ask-user-question@^2.12.0"
        "npm:@narumitw/pi-btw@^0.61.1"
        "npm:pi-wakatime@^1.1.3"
      ];
    };

    home.file.".pi/agent/zentui.json".text = builtins.toJSON {
      components = {
        editor = {
          enabled = true;
          style = "opencode-copy-friendly";
          colorSource = "theme";
          borderColorMode = "static";
          modelLabel = "id";
          viewportIndicators = true;
          styles = {
            opencode-copy-friendly = {
              metadataFormat = "$model  $provider(  $thinking)";
              completionMenu = "palette";
            };
            accent-rail = {
              rail = "▎";
              asciiRail = "|";
              transparent = false;
            };
          };
        };
        footer = {
          style = "starship";
          colorSource = "theme";
          modelLabel = "id";
          styles.starship = {
            format = "";
            responsive = true;
            compactFormat = "$cwd$wrap(in $session_name)$wrap(on $git_branch) $git_status$wrap$context$wrap_sep$tokens";
            compactMaxLines = 2;
            separator = "pipe";
            contextStyle = "text";
            contextThresholds = {
              warning = 70;
              error = 90;
            };
            pathDisplay = {
              mode = "basename";
              depth = 0;
            };
            segments = {
              cwd = true;
              sessionName = true;
              gitBranch = true;
              gitStatus = true;
              gitCounts = false;
              gitCommit = false;
              gitMetrics = false;
              runtime = true;
              modelInfo = false;
              context = true;
              tokens = true;
              cost = true;
              sessionDuration = false;
              username = false;
              time = false;
              os = false;
              packageVersion = false;
            };
            gitBranch.maxLength = "full";
            gitCommit = {
              hashLength = 7;
              onlyDetached = true;
              showTag = true;
            };
            gitMetrics = {
              onlyNonzero = true;
              ignoreSubmodules = false;
            };
            extensionStatuses = {
              defaultPlacement = "right";
              placements = { };
              colorModes = { };
            };
          };
        };
        userMessages = {
          enabled = true;
          style = "framed-copy-friendly";
          colorSource = "theme";
          styles = {
            framed-copy-friendly = { };
          };
        };
        thinkingSteps = {
          enabled = true;
          mode = "summary";
        };
        workingLine = {
          enabled = true;
          turnSummary = true;
          spinner = "star-bloom";
          spinnerIntervalMs = 100;
          animateSpinnerColor = false;
          textIntervalMs = 60;
          textAnimation = "classic";
          colorSource = "theme";
          messages = {
            custom = true;
            values = [
              "Sautéing…"
              "Cooking…"
              "Ionizing…"
              "Zigzagging…"
              "Razzle-dazzling…"
              "Photosynthesizing…"
              "Nucleating…"
              "Brewing…"
              "Combobulating…"
              "Boogieing…"
              "Befuddling…"
              "Alchemizing…"
              "Conjuring…"
              "Baking…"
              "Simmering…"
              "Blanching…"
            ];
          };
          segments = {
            tool = true;
            elapsed = true;
            thought = true;
            tokens = true;
          };
        };
        selectorBorders = {
          enabled = true;
          style = "zentui";
          colorSource = "terminal";
        };
      };
      icons.mode = "nerd";
    };
  };
}
