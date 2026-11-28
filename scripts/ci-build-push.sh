#!/usr/bin/env bash
# CI 分组构建 + 推送缓存 + 立即清理，避免单个 job 把 runner 磁盘占满。
#
# 用法（在仓库根目录执行，可多次调用）：
#   scripts/ci-build-push.sh host:<hostname>        构建某台主机的 toplevel
#   scripts/ci-build-push.sh flake-packages         构建全部 flake 自有包
#   scripts/ci-build-push.sh overlay-packages       构建全部 overlay 覆盖的包
#
# 每组流程：nix build（gcroot 保护）→ attic/cachix push 闭包 → 删 gcroot →
# nix store delete 顶层路径 → nix store gc。依赖随后续组需要时从缓存重新取回，
# 换取磁盘峰值只相当于单组闭包大小。
#
# 环境变量：
#   ATTIC_PUSH_TOKEN  设置后推 Attic（需先 attic login）
#   否则回落到 cachix push（与 auto-update.yml 原行为一致）

set -euo pipefail

group="${1:?用法: ci-build-push.sh host:<hostname>|flake-packages|overlay-packages}"

expr_for() {
  case "$1" in
    host:*)
      local host="${1#host:}"
      # 未加引号的 EOF：需要展开 ${host}。
      # 主机名带连字符（yc-hk-1 等），静态属性路径会被解析成减法，
      # 必须用 getAttr 动态访问。
      cat <<EOF
let
  flake = builtins.getFlake (toString ./.);
  host = builtins.getAttr "${host}" flake.nixosConfigurations;
in
  host.config.system.build.toplevel
EOF
      ;;
    flake-packages)
      cat <<'EOF'
let
  flake = builtins.getFlake (toString ./.);
  pkgs = flake.nixosConfigurations.nixos-desktop.pkgs;
  system = pkgs.stdenv.hostPlatform.system;
in
  builtins.attrValues flake.packages.${system}
EOF
      ;;
    overlay-packages)
      cat <<'EOF'
let
  flake = builtins.getFlake (toString ./.);
  lib = flake.inputs.nixpkgs.lib;
  pkgs = flake.nixosConfigurations.nixos-desktop.pkgs;
  overlayNames = lib.unique (
    lib.concatMap
      (ov: builtins.attrNames (ov pkgs pkgs))
      (builtins.attrValues flake.overlays)
  );
in
  map (n: pkgs.${n}) overlayNames
EOF
      ;;
    *)
      echo "未知构建组: $1" >&2
      exit 64
      ;;
  esac
}

push_paths() {
  local cache="rhen:${ATTIC_CACHE:-public}"
  if [ -n "${ATTIC_PUSH_TOKEN:-}" ]; then
    echo "==> 推送到 Attic（$cache）"
    attic push "$cache" "$@"
  else
    echo "==> ATTIC_PUSH_TOKEN 未设置，回落到 Cachix（rhencloud）"
    cachix push rhencloud "$@"
  fi
}

echo "::group::构建 $group"
expr="$(expr_for "$group")"
gcroots="$(mktemp -d)"

# out-link 作为临时 gcroot，防止构建后 / 推送前被自动 GC（min-free）回收。
# nix.conf 已开 keep-going：个别包失败时其余目标照常构建完，
# 已产出的路径仍值得推送缓存，避免下次全部重编。
build_rc=0
nix build -L --impure --print-out-paths --out-link "$gcroots/out" \
  --expr "$expr" | tee "$gcroots/paths.txt" || build_rc=$?

mapfile -t paths < "$gcroots/paths.txt"
echo "::endgroup::"

if [ "$build_rc" -ne 0 ] && [ "${#paths[@]}" -gt 0 ]; then
  echo "::warning::$group 部分目标构建失败（rc=$build_rc），仍推送已成功的 ${#paths[@]} 个路径"
fi

if [ "${#paths[@]}" -eq 0 ]; then
  echo "==> $group 没有产出路径，跳过推送"
  rm -rf "$gcroots"
  # 构建全挂时以原退出码失败，让 workflow 如实报错
  [ "$build_rc" -ne 0 ] && exit "$build_rc"
  exit 0
fi

echo "::group::推送 $group（${#paths[@]} 个顶层路径）"
push_paths "${paths[@]}"
echo "::endgroup::"

echo "::group::清理 $group 本地 store 路径"
# 先撤掉 gcroot，再删顶层路径，最后 gc 回收不再被引用的依赖
rm -rf "$gcroots"
nix store delete "${paths[@]}" || echo "::warning::部分路径删除失败，交由 gc 处理"
nix store gc
df -h /nix | tail -1
echo "::endgroup::"

# 部分目标失败时，已成功的路径已推送缓存，但本组不能算全绿：
# 以非零退出，让 workflow 停在这里、不开自动合并的 PR。
if [ "$build_rc" -ne 0 ]; then
  echo "::error::$group 有目标构建失败，已推送成功部分后退出"
  exit "$build_rc"
fi
