{ lib, ... }:
{
  options.rhencloud.aider = {
    enable = lib.mkEnableOption "aider AI coding assistant";
    defaultProvider = lib.mkOption {
      type = lib.types.enum [
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
}
