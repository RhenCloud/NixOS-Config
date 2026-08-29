{ pkgs, ... }:
# 在 bubblewrap 沙箱中用 tmpfs 提供临时 home / tmp，测试不落盘
pkgs.writeShellScriptBin "sandbox" ''
  #!${pkgs.bash}/bin/bash
  set -euo pipefail

  workdir="''${SANDBOX_WORKDIR:-$PWD}"

  exec ${pkgs.bubblewrap}/bin/bwrap \
    --ro-bind /nix/store /nix/store \
    --ro-bind /run/current-system /run/current-system \
    --ro-bind /etc /etc \
    --tmpfs /tmp \
    --tmpfs "$HOME" \
    --bind "$workdir" "$workdir" \
    --chdir "$workdir" \
    --dev /dev \
    --proc /proc \
    --unshare-pid \
    --unshare-ipc \
    --die-with-parent \
    "''${@:-''${SHELL:-/bin/sh}}"
''