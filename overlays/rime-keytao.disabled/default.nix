{ ... }: final: prev: {
  rime-keytao = prev.rime-keytao.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      # 补丁文件放到 overlays/rime-keytao/patches/ 目录
      # 用 sed 自动生成补丁的示例：
      # (final.runCommand "schema-patch" { } ''
      #   cp ${old.src}/schema/desktop/keytao.schema.yaml $out
      #   sed -i 's/page_size: 6/page_size: 8/' $out
      # '')
    ];

    postInstall =
      (old.postInstall or "")
      + ''
        # 在 $out/share/rime-data/ 下添加或修改文件
        # 例如添加自定义词典：
        # cp ${./dict.dict.yaml} "$out/share/rime-data/dict.dict.yaml"

        # 修改 keytao.extended.dict.yaml 启用/禁用扩展词库
        # substituteInPlace "$out/share/rime-data/keytao.extended.dict.yaml" \
        #   --replace "#  - keytao.css" "  - keytao.css"
      '';
  });
}
