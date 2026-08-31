{ self, writeText, ... }:
let
  # 只用 drvPath 强制配置求值；移除字符串上下文，避免 GC 后陈旧 eval cache
  # 让该轻量检查依赖一个已经不存在的 .drv 文件。
  drvPath = builtins.unsafeDiscardStringContext self.nixosConfigurations.nixos-desktop.config.system.build.toplevel.drvPath;
in
writeText "eval-nixos-desktop" "${drvPath}\n"
