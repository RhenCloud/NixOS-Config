{
  config,
  lib,
  ...
}:
with lib;
{
  options.rhen.btrfs = {
    enable = mkEnableOption "启用 Btrfs 配额和优化" // {
      default = true;
    };
  };
}
