{ lib, stdenvNoCC, pkgs, python3, rime-keytao }:

stdenvNoCC.mkDerivation {
  pname = "ice2keytao";
  version = "1.0";
  src = ./../../scripts;
  buildInputs = [ python3 pkgs.rime-ice rime-keytao ];
  buildPhase = ''
    mkdir -p "$out/share/rime-data"
    python3 "$src/convert-rime-ice-to-keytao.py" \
      "${pkgs.rime-ice}/share/rime-data/cn_dicts" \
      "${rime-keytao}/share/rime-data/keytao.phrase.dict.yaml" \
      "${rime-keytao}/share/rime-data/keytao.single.dict.yaml" \
      "$out/share/rime-data/ice2keytao.dict.yaml"
  '';
  installPhase = ''
    true
  '';
  meta = with lib; {
    description = "从 rime-ice base.dict.yaml 提取二字词并转换为键道6 编码";
    license = licenses.free;
  };
}
