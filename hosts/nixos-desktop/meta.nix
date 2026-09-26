# 静态元数据：框架从此读取架构与角色策略，
# default.nix 只由 NixOS module system 求值。
{
  system = "x86_64-linux";
  roles = [
    "desktop"
    "dev"
  ];
  profiles = [
    "desktop"
    "dev"
  ];

  # 与系统共享 nixpkgs 实例，消除嵌入式 HM 的重复实例化开销（冷 eval 约省 12% CPU）
  home.useGlobalPkgs = true;
}
