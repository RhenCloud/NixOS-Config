# 静态元数据：框架从此读取架构、角色和 Home Manager 策略，
# default.nix 只由 NixOS module system 求值。
{
  system = "x86_64-linux";
  roles = [ "server" ];

  # yc-hk-1 的 Home Manager 通过 deploy-rs 独立部署，
  # 不需要嵌入到 NixOS 系统中。
  home.embed = false;
}
