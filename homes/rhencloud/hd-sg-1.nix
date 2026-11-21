{ lib, ... }:
{
  # hd-sg-1 使用独立 Home Manager 配置，由 deploy-rs 单独激活。
  home.stateVersion = lib.mkDefault "26.11";
}
