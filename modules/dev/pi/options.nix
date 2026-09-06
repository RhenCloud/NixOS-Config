{ lib, ... }:
{
  options.rhencloud.pi = {
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
      ];
      default = "voidswitch";
      description = "默认 LLM 供应商";
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
