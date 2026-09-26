{ lib, ... }:
{
  options.rhencloud.meli.enable = lib.mkEnableOption "meli 终端邮件客户端";
}
