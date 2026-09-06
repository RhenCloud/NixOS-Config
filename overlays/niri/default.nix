# 全局改用 niri-flake 的 niri-unstable，并打 pin 窗口规则补丁。补丁仅针对该
# 版本源码编写；仅当源码尚未内置该特性时才应用，避免把补丁误用到 nixpkgs 的
# niri 上。系统 niri（`sessionPackages`/`xdg.configPackages`）与 home-manager
# 的 niri 都经此统一为同一个 niri-unstable，不再构建 nixpkgs 26.04 的 niri。
{ inputs, ... }:
_final: prev: {
  niri = inputs.niri.packages.${prev.stdenv.hostPlatform.system}.niri-unstable.overrideAttrs (old: {
    prePatch = ''
      ${old.prePatch or ""}
      if ! grep -q "pub pin" niri-config/src/window_rule.rs; then
        patch -p1 -N --no-backup-if-mismatch -i ${../../patches/niri/pin.patch}
      fi
    '';
  });
}
