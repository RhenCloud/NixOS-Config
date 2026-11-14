{
  inputs,
  pkgs,
}:

inputs.ttt.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
  vendorHash = "sha256-Snis8gmPqxuuO9+RJxEasHlUg5GVdV6GgNH4UTkCBvs=";
  patches = (old.patches or [ ]) ++ [
    # 新版 TTT 已内置符号链接插件目录支持。
  ];

  meta = old.meta // {
    description = "Terminal Text Tool with CJK-safe Markdown previews";
  };
})
