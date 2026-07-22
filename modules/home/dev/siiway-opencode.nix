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
      # agent-session-status = {
      #   enabled = true;
      #   type = "remote";
      #   url = "http://127.0.0.1:55854/mcp";
      #   headers = {
      #     Authorization = "Bearer 81cd0b3f83bfacf53bb0c61dad0cc04d3d6bdca850b66de80d0a22def1c858b8";
      #     X-Agent = "opencode";
      #   };
      # };
    };
    plugin = [
      # "oh-my-openagent@latest"
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
          apiKey = "REDACTED-8291f870";
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
      # opencode = {
      #   models = {
      #     "deepseek-v4-pro".name = "";
      #   };
      #   npm = "@ai-sdk/openai-compatible";
      #   options = {
      #     apiKey = "REDACTED-5fcc9ef0";
      #     baseURL = "https://token.android-doc.com/api/token/v1";
      #     setCacheKey = true;
      #   };
      # };
      voidswitch = {
        npm = "@ai-sdk/openai-compatible";
        name = "VoidSwitch";
        options = {
          apiKey = "REDACTED-71bdd162";
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
