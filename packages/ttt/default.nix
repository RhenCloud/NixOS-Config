{
  inputs,
  pkgs,
}:

inputs.ttt.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
  vendorHash = "sha256-gQmx2AMj0FpWb8y7mj24YVEuxkvJsXoOcNKMdgNqreA=";
  # 新版 TTT 已内置符号链接插件目录支持，无需额外补丁。
  patches = old.patches or [ ];

  meta = old.meta // {
    description = "Terminal Text Tool with CJK-safe Markdown previews";
  };
})
