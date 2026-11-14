# nixpkgs 26.11.20261103 中 opencode 2.2.5 的 node_modules 固定输出哈希已过期：
# 上游 npm 归档内容发生变化，nixpkgs master 已把它修正为
# sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=（Linux）。
#
# 这里仅在版本仍为 2.2.5 时替换哈希，避免升级 nixpkgs 后把旧哈希套到新版本上。
# nixpkgs 更新到包含该修复的版本后，本 overlay 与 overlays/opencode-node-modules-hash/ 都可以删除。
_final: prev: {
  opencode =
    if prev.opencode.version == "2.2.5" then
      prev.opencode.overrideAttrs (old: {
        node_modules = old.node_modules.overrideAttrs (_: {
          outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
        });
      })
    else
      prev.opencode;
}
