{
  inputs,
  lib,
  pkgs,
}:

inputs.ttt.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
  vendorHash = "sha256-Rlv/akRDQwbbpGblCaVoWRPQnspg0Ijt7bpm3jYmDeE=";
  patches = (old.patches or [ ]) ++ [
    # 新版 TTT 已内置符号链接插件目录支持。
  ];

  meta = old.meta // {
    description = "Terminal Text Tool with CJK-safe Markdown previews";
  };
})
