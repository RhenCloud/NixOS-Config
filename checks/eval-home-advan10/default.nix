{ self, writeText, ... }:
let
  # 与主机求值检查相同，只验证 activationPackage 可求值，不把整个
  # Home Manager generation 的 .drv 上下文带入轻量检查。
  drvPath =
    builtins.unsafeDiscardStringContext
      self.homeConfigurations."advan10@yc-hk-1".activationPackage.drvPath;
in
writeText "eval-home-advan10" "${drvPath}\n"
