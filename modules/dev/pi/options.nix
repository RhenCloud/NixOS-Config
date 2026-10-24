{ lib, ... }:
{
  options.rhen.pi = {
    enable = lib.mkEnableOption "Pi coding agent";
    defaultProvider = lib.mkOption {
      type = lib.types.enum [
        "voidswitch"
        # "frimodel"
        # "local"
        # "sub2api"
        # "zhi"
        "chibang-codex"
        "chibang-claude"
        "chibang-cn"
      ];
      default = "voidswitch";
      description = "默认 LLM 供应商";
    };
    defaultModel = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "默认模型 ID（留空则按 defaultProvider 自动映射推荐默认模型）";
    };
    theme = lib.mkOption {
      type = lib.types.enum [
        "dark"
        "light"
        "dracula"
      ];
      default = "dracula";
      description = "Pi TUI 主题";
    };
  };
}
