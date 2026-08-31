# 静态元数据：框架从此读取架构与角色策略，
# default.nix 只由 NixOS module system 求值。
{
  system = "x86_64-linux";
  roles = [ "desktop" ];

  # Stylix 的 Home Manager 模块需要向 HM 自己的 nixpkgs 追加 overlays。
  home.useGlobalPkgs = false;
}
