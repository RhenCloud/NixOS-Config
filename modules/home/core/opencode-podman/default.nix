{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.opencode-podman;

  containerImage = "localhost/opencode-dev:latest";

  entrypoint = pkgs.runCommand "entrypoint" { } ''
    mkdir -p $out/bin
    cat > $out/bin/entrypoint.sh << 'SCRIPT'
    #!/bin/bash
    set -euo pipefail
    if [ ! -d /nix/store ]; then
      mkdir -p /nix
      nix-store --init 2>/dev/null || true
    fi
    exec "$@"
    SCRIPT
    chmod +x $out/bin/entrypoint.sh
  '';

  etcFiles = pkgs.runCommand "etc-files" { } ''
    mkdir -p $out/etc $out/home/user $out/root
    echo "root:x:0:0::/root:/bin/bash" > $out/etc/passwd
    echo "root:x:0:" > $out/etc/group
  '';

  image = pkgs.dockerTools.buildLayeredImage {
    name = "opencode-dev";
    tag = "latest";

    contents = [
      pkgs.git
      pkgs.openssh
      pkgs.ripgrep
      pkgs.fd
      pkgs.jq
      pkgs.coreutils
      pkgs.bash
      pkgs.python3
      pkgs.uv
      pkgs.nodejs
      pkgs.chromium
      entrypoint
      etcFiles
    ];

    config = {
      Cmd = [ "bash" ];
      WorkingDir = "/workspace";
      Entrypoint = [ "${entrypoint}/bin/entrypoint.sh" ];
    };
  };

  containerOpencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    model = "voidswitch/deepseek-v4-pro";
    small_model = "voidswitch/glm-4.7-flash-cf";
    mcp = {
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
        command = [ "uvx" "mcp-nixos" ];
        enabled = true;
        type = "local";
      };
      playwright = {
        command = [
          "npx" "-y" "@playwright/mcp@latest"
          "--browser" "chromium"
          "--headless"
        ];
        enabled = true;
        type = "local";
      };
    };
    plugin = [
      "opencode-chrome-devtools"
      "@tarquinen/opencode-dcp@latest"
      "@nick-vi/opencode-type-inject"
      "remote-code"
    ];
    provider = {
      FriModel = {
        models."gpt-5.4".name = "";
        npm = "@ai-sdk/openai-compatible";
        options = {
          apiKey = config.sops.placeholder."opencode-frimodel-api-key";
          baseURL = "https://api.frimodel.com/v1";
          setCacheKey = true;
        };
      };
      sub2api = {
        models."gpt-5.5".name = "";
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
          "gpt-5.6-luna" = { };
        };
      };
      zhi = {
        models."qwen3.7-max".name = "";
        npm = "@ai-sdk/openai-compatible";
        options = {
          apiKey = config.sops.placeholder."opencode-zhi-api-key";
          baseURL = "https://zhi-api.com/v1";
          setCacheKey = true;
        };
      };
    };
  };

  opencodeWrapper = pkgs.writeShellScriptBin "opencode-sandboxed" ''
    set -euo pipefail

    PROJECT_DIR="''${OPENCODE_PROJECT_DIR:-$(pwd)}"
    IMAGE="${containerImage}"
    CONTAINER_NAME="opencode-dev"
    PROJECT_NAME="$(basename "$PROJECT_DIR")"

    if ! podman image exists "$IMAGE" 2>/dev/null; then
      echo "加载 OpenCode 容器镜像..." >&2
      podman load -i ${image}
    fi

    if podman container exists "$CONTAINER_NAME" 2>/dev/null; then
      STATE=$(podman inspect --format '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "stopped")
      if [ "$STATE" != "running" ]; then
        podman start "$CONTAINER_NAME" > /dev/null 2>&1
      fi
      podman exec -it \
        -w "/workspace/$PROJECT_NAME" \
        "$CONTAINER_NAME" \
        opencode --auto "$@"
      exit 0
    fi

    exec podman run -it \
      --name "$CONTAINER_NAME" \
      --workdir "/workspace/$PROJECT_NAME" \
      -v "''${PROJECT_DIR}:/workspace/$PROJECT_NAME:rw,Z" \
      -v "${config.home.homeDirectory}/.config/opencode/container-opencode.json:/root/.config/opencode/opencode.json:ro,Z" \
      -v "${config.home.homeDirectory}/.config/opencode/AGENTS.md:/root/.config/opencode/AGENTS.md:ro,Z" \
      -v "${config.home.homeDirectory}/.config/opencode/agents:/root/.config/opencode/agents:ro,Z" \
      -v "${config.home.homeDirectory}/.config/opencode/skills:/root/.config/opencode/skills:ro,Z" \
      -v "${config.home.homeDirectory}/.config/opencode/plugins:/root/.config/opencode/plugins:ro,Z" \
      -v "${config.home.homeDirectory}/.ssh:/root/.ssh:ro,Z" \
      -v "${config.home.homeDirectory}/.config/git/config:/root/.config/git/config:ro,Z" \
      -e TERM \
      -e HOME=/root \
      -e GIT_CONFIG_COUNT=4 \
      -e GIT_CONFIG_KEY_0=user.useConfigOnly \
      -e GIT_CONFIG_VALUE_0=true \
      -e GIT_CONFIG_KEY_1=commit.gpgsign \
      -e GIT_CONFIG_VALUE_1=true \
      -e GIT_CONFIG_KEY_2=gpg.format \
      -e GIT_CONFIG_VALUE_2=ssh \
      -e GIT_CONFIG_KEY_3=user.signingkey \
      -e "GIT_CONFIG_VALUE_3=/root/.ssh/id_ed25519.pub" \
      "$IMAGE" \
      opencode --auto "$@"
  '';
in
{
  options.rhencloud.opencode-podman = {
    enable = mkEnableOption "opencode Podman sandbox";
  };

  config = mkIf cfg.enable {
    home.packages = [ opencodeWrapper ];

    sops.templates."opencode-container.json" = {
      content = builtins.toJSON containerOpencodeConfig;
    };

    xdg.configFile."opencode/container-opencode.json".source =
      config.lib.file.mkOutOfStoreSymlink
        config.sops.templates."opencode-container.json".path;
  };
}
