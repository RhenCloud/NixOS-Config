{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.aider;
  envFile = "/run/secrets/rendered/aider.env";
in
{
  options.rhencloud.aider = {
    enable = mkEnableOption "aider AI coding assistant";
    defaultProvider = mkOption {
      type = types.enum [
        "voidswitch"
        "frimodel"
        "local"
        "sub2api"
        "zhi"
      ];
      default = "voidswitch";
      description = "默认 LLM 供应商";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ aider-chat ];

    xdg.configFile."aider/aider.conf.yml".source =
      config.lib.file.mkOutOfStoreSymlink "/run/secrets/rendered/aider.conf.yml";

    home.file.".aider.model.settings.yml".source =
      config.lib.file.mkOutOfStoreSymlink "/run/secrets/rendered/aider.model.settings.yml";

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