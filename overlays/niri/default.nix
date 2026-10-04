# 全局改用 niri-flake 的 niri-unstable，打 pin 窗口规则补丁，并锁定 Cargo 依赖
# 避免在 nix eval 阶段由 allowBuiltinFetchGit 动态拉取外部 git 仓库（Smithay）。
{ inputs, snowveil, ... }:
_final: prev: {
  niri =
    let
      niri-base = inputs.niri.packages.${prev.stdenv.hostPlatform.system}.niri-unstable;
    in
    niri-base.overrideAttrs (old: {
      cargoDeps = prev.rustPlatform.importCargoLock {
        lockFile = "${niri-base.src}/Cargo.lock";
        outputHashes = {
          "smithay-0.7.0" = "sha256-f617WH8AibdaR8plQtkwegZP+pEMDcM5DpeJmDXqd0g=";
        };
      };
      prePatch = ''
        ${old.prePatch or ""}
        if ! grep -q "pub pin" niri-config/src/window_rule.rs; then
          patch -p1 -N --no-backup-if-mismatch -i ${snowveil.patches.local ../../patches/niri/pin.patch}
        fi
      '';
    });
}
