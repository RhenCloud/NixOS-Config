{
  config,
  lib,
  pkgs,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhencloud.aider;
  envFile = config.sops.templates."aider.env".path;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [ aider-chat ];

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
    };

    sops.templates = {
      "aider.env" = {
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
    };

    xdg.configFile."aider/aider.conf.yml".source =
      config.lib.file.mkOutOfStoreSymlink
        config.sops.templates."aider.conf.yml".path;

    home.file.".aider.model.settings.yml".source =
      config.lib.file.mkOutOfStoreSymlink
        config.sops.templates."aider.model.settings.yml".path;

    programs.fish.functions = {
      aider = {
        body = ''
          source ${envFile}
          set -gx ANTHROPIC_API_KEY $VOIDSWITCH_API_KEY
          set -gx ANTHROPIC_BASE_URL "https://voidswitch.siiway.org/v1"
          command aider $argv
        '';
      };
      aider-frimodel = {
        body = ''
          source ${envFile}
          set -gx OPENAI_API_KEY $FRIMODEL_API_KEY
          set -gx OPENAI_API_BASE "https://api.frimodel.com/v1"
          command aider --model "openai/gpt-5.4" $argv
        '';
      };
      aider-local = {
        body = ''
          source ${envFile}
          set -gx OPENAI_API_KEY $LOCAL_API_KEY
          set -gx OPENAI_API_BASE "http://127.0.0.1:8080/v1"
          command aider --model "openai/gpt-5.5" $argv
        '';
      };
      aider-sub2api = {
        body = ''
          source ${envFile}
          set -gx OPENAI_API_KEY $SUB2API_KEY
          set -gx OPENAI_API_BASE "https://sub2api.wss.moe"
          command aider --model "openai/gpt-5.5" $argv
        '';
      };
      aider-zhi = {
        body = ''
          source ${envFile}
          set -gx OPENAI_API_KEY $ZHI_API_KEY
          set -gx OPENAI_API_BASE "https://zhi-api.com/v1"
          command aider --model "openai/qwen3.7-max" $argv
        '';
      };
    };
  };
}
