{
  inputs,
  lib,
  pkgs,
}:

inputs.ttt.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [
    ../../patches/ttt/markdown-cjk-width.patch
    # TTT 原版 LoadAll 用 entry.IsDir() 过滤目录，不会跟随符号链接，
    # 导致 home-manager 以 symlink 部署的插件（~/.config/ttt/plugins/*）
    # 全部被跳过、且手工安装的目录因不在 registry 里反复弹审批框。
    # 此补丁让 symlink 指向的目录也能被识别。
    ../../patches/ttt/plugin-symlink-load.patch
  ];

  meta = old.meta // {
    description = "Terminal Text Tool with CJK-safe Markdown previews";
  };
})
