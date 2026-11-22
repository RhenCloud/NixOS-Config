{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  glibc,
}:
let
  version = "27.2.1";
in
stdenv.mkDerivation {
  pname = "tokens";
  inherit version;

  src = fetchurl {
    url = "https://github.com/missuo/tokens/releases/download/v${version}/tokens-v${version}-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-cx8slkzQ1CLEdGLcb9kiE66LN2qoELvvecrt4/KYE18=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ glibc ];

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 tokens $out/bin/tokens
    runHook postInstall
  '';

  meta = {
    description = "tokens.ci CLI，AI 编码用量排行榜统计工具";
    homepage = "https://tokens.ci";
    license = lib.licenses.mit;
    mainProgram = "tokens";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
