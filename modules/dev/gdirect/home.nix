{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
let
  cfg = config.rhen.gdirect;
  system = pkgs.stdenv.hostPlatform.system;
  gdirectPackages = inputs.gdirect.packages.${system};

  # 上游 flake 的 buildInputs 只有 openssl，但 gdirect 通过 rusqlite
  # 链接了 -lsqlite3，导致链接阶段报 `cannot find -lsqlite3`。
  # 这里补上链接期缺失的库。
  #
  # gdirect-desktop 另有一个上游问题：desktop/Cargo.lock 锁 unicode-width 0.2.3，
  # 而根 Cargo.lock 锁 0.2.2，nixpkgs 的 cargoDeps 只 vendor 根 lock，
  # 导致 `candidate versions found which didn't match: 0.2.3`。
  # 因此桌面版暂不启用，待上游修复。
  patchGdirect =
    drv:
    drv.overrideAttrs (old: {
      buildInputs = (old.buildInputs or [ ]) ++ [
        pkgs.sqlite
        pkgs.zlib
      ];
    });

  # 桌面版：cargo 解析 `gdirect = { path = ".." }` 时会向上找到根 Cargo.lock
  # （unicode-width 0.2.2），而 cargoDeps 只 vendor 了 desktop/Cargo.lock 的
  # 0.2.3，导致 `candidate versions found which didn't match: 0.2.3`。
  # 把根的 lock 覆盖成 desktop 的，使 cargo 与 vendor 目录一致。
  #
  # 另：上游 postInstall 用的是相对 desktop 的路径，但 cargoInstallHook 会把
  # 工作目录切到源根，导致 assets/gdirect.png 找不到，这里一并修正。
  patchGdirectDesktop =
    drv:
    (patchGdirect drv).overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        if [ -f desktop/Cargo.lock ]; then
          cp desktop/Cargo.lock Cargo.lock
        fi
      '';
      postInstall = ''
        # cargoInstallHook 按根 crate 名装成 bin/gdirect，
        # 但桌面入口与用户预期都是 gdirect-desktop，重命名对齐。
        if [ -e "$out/bin/gdirect" ] && [ ! -e "$out/bin/gdirect-desktop" ]; then
          mv "$out/bin/gdirect" "$out/bin/gdirect-desktop"
        fi
        install -Dm644 desktop/assets/gdirect.png $out/share/icons/hicolor/512x512/apps/gdirect.png
        install -Dm644 desktop/packaging/gdirect.desktop $out/share/applications/gdirect.desktop
        install -Dm644 LICENSE $out/share/licenses/gdirect-desktop/LICENSE
        install -Dm644 desktop/assets/fonts/OFL.txt $out/share/licenses/gdirect-desktop/FONTS-OFL.txt
      '';
    });

  gdirect = patchGdirect gdirectPackages.gdirect;
  gdirectDesktop = patchGdirectDesktop gdirectPackages.gdirect-desktop;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      gdirect
      gdirectDesktop
      pkgs.rclone
    ];
  };
}
