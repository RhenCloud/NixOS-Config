{
  lib,
  ...
}:
{
  options.rhencloud.tokens.enable = lib.mkEnableOption "tokens.ci AI 编码用量统计上传";
}
