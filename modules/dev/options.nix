{ lib, ... }:
{
  options.rhencloud.roles.dev.enable = lib.mkEnableOption "开发角色（语言工具链、编辑器与 AI 编程工具）";
}
