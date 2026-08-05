{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  system = pkgs.stdenv.hostPlatform.system;
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
    };
    plugin = [
      "${inputs.siiway-oc-plugin.packages.${system}.opencode-voidswitch}"
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
          apiKey = config.sops.placeholder."opencode-zhi-api-key";
          baseURL = "https://zhi-api.com/v1";
          setCacheKey = true;
        };
      };
    };
  };
in {
  config = mkIf config.my.isDesktop {
    sops.secrets = {
      "sleepy-token" = {
        sopsFile = ../../../secrets/common.yaml;
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
      };
      "github-token" = {
        sopsFile = ../../../secrets/common.yaml;
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
      };
      "npm-token" = {
        sopsFile = ../../../secrets/hosts/nixos-desktop.yaml;
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
      };
      "opencode-frimodel-api-key" = {
        sopsFile = ../../../secrets/hosts/nixos-desktop.yaml;
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
      };
      "opencode-local-api-key" = {
        sopsFile = ../../../secrets/hosts/nixos-desktop.yaml;
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
      };
      "opencode-sub2api-key" = {
        sopsFile = ../../../secrets/hosts/nixos-desktop.yaml;
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
      };
      "opencode-voidswitch-api-key" = {
        sopsFile = ../../../secrets/hosts/nixos-desktop.yaml;
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
      };
      "opencode-zhi-api-key" = {
        sopsFile = ../../../secrets/hosts/nixos-desktop.yaml;
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
      };
      "ssh-tc-discourse" = {
        sopsFile = ../../../secrets/hosts/nixos-desktop.yaml;
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
      };
      "ssh-bee-hk-1" = {
        sopsFile = ../../../secrets/hosts/nixos-desktop.yaml;
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
      };
    };

    sops.templates = {
      "aider.env" = {
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
        content = ''
          export VOIDSWITCH_API_KEY="${config.sops.placeholder."opencode-voidswitch-api-key"}"
          export FRIMODEL_API_KEY="${config.sops.placeholder."opencode-frimodel-api-key"}"
          export LOCAL_API_KEY="${config.sops.placeholder."opencode-local-api-key"}"
          export SUB2API_KEY="${config.sops.placeholder."opencode-sub2api-key"}"
          export ZHI_API_KEY="${config.sops.placeholder."opencode-zhi-api-key"}"
        '';
      };

      "aider.conf.yml" = {
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
        content = ''
          model: anthropic/claude-opus-4-8
          dark-mode: true
          vim: true
          map-refresh: auto
          auto-commits: false
          dirty-commits: false
          attribute-author: false
          attribute-committer: false
          watch-files: true
          editor: nvim
        '';
      };

      "aider.model.settings.yml" = {
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
        content = ''
          - name: anthropic/claude-opus-4-8
            extra_params:
              extra_headers:
                x-api-key: ${config.sops.placeholder."opencode-voidswitch-api-key"}
          - name: openai/gpt-5.4
            extra_params:
              extra_headers:
                x-api-key: ${config.sops.placeholder."opencode-frimodel-api-key"}
          - name: openai/qwen3.7-max
            extra_params:
              extra_headers:
                x-api-key: ${config.sops.placeholder."opencode-zhi-api-key"}
        '';
      };

      "opencode.json" = {
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
        content = builtins.toJSON opencodeConfig;
      };

      "npmrc" = {
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
        content = config.sops.placeholder."npm-token";
      };

      "ssh-host-blocks" = {
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0644";
        content =
          config.sops.placeholder."ssh-tc-discourse"
          + "\n\n"
          + config.sops.placeholder."ssh-bee-hk-1"
          + "\n";
      };

      "piri.toml" = {
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
        content = ''
          [niri]

          [piri.plugins]
          scratchpads = true
          empty = false
          window_rule = true
          autofill = true
          singleton = true
          window_order = true
          swallow = true
          workspace_rule = true
          fcitx5 = true
          sleepy = true

          [piri.scratchpad]
          default_size = "40% 60%"
          default_margin = 50

          [scratchpads.musicfox]
          direction = "fromTop"
          command = "kitty --class musicfox musicfox"
          app_id = "float.musicfox"
          size = "60% 40%"
          margin = 150

          [empty.1]
          command = "vesktop ; zen ; linuxqq"

          [empty.2]
          command = "kitty"

          [sleepy]
          server_url = "https://sleepy.rhen.cloud"
          device_id = "nixos-desktop"
          device_name = "NixOS Desktop"
          token = "${config.sops.placeholder."sleepy-token"}"
          secret = ""
          prefer_app_id = false

          media_process_name = "splayer|musicfox"
          media_device_id = "nixos-desktop-media"
          media_device_name = "NixOS-Desktop Media"
          media_poll_interval = 5

          [[fcitx5]]
          app_id = "zen"
          input_mode = "english"

          [[fcitx5]]
          app_id = "kitty"
          input_mode = "english"

          [[fcitx5]]
          app_id = "code"
          input_mode = "english"

          [[fcitx5]]
          app_id = "QQ"
          input_mode = "chinese"

          [[fcitx5]]
          app_id = "wechat"
          input_mode = "chinese"

          [[fcitx5]]
          app_id = "vesktop"
          input_mode = "chinese"

          [[fcitx5]]
          app_id = "dev.zed.Zed"
          input_mode = "english"
        '';
      };

      "pyprland.toml" = {
        owner = "rhencloud";
        group = "rhencloud";
        mode = "0400";
        content = ''
          [pyprland]
          plugins = [
              "toggle_special",
              "fetch_client_menu",
              "expose",
              "cloud_pyprland.fcitx5_switcher",
              "cloud_pyprland.hdrop",
          ]

          [cloud_pyprland.sleepy]
          server_url = "https://sleepy.rhen.cloud"
          device_name = "Arch Linux"
          device_id = "archlinux"
          token = "${config.sops.placeholder."sleepy-token"}"

          [cloud_pyprland.fcitx5_switcher]
          active_classes = ["wechat", "QQ", "zoom"]
          inactive_classes = [
              "code",
              "kitty",
              "musicfox",
              "google-chrome",
              "clipse",
              "org.wezfurlong.wezterm",
              "firefox",
          ]
          active_titles = ["微信"]
          inactive_titles = ["Minecraft .*"]

          [cloud_pyprland.hdrop.wechat]
          class = "wechat"
          floating = true
          center = true
          height = 700
          width = 1000
          launch_on_missing = false

          [cloud_pyprland.hdrop.musicfox]
          class = "musicfox"
          command = "kitty --class musicfox musicfox"
          floating = true
          center = true
          height = 700
          width = 1200
          launch_on_missing = true
        '';
      };
    };
  };
}
