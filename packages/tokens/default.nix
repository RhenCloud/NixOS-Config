{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  glibc,
}:

stdenv.mkDerivation {
  pname = "tokens";
  version = "27.1.1";

  src = fetchurl {
    url = "https://github.com/missuo/tokens/releases/download/v27.1.1/tokens-v27.1.1-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-n8kpe6hiAvw3FV813cM2l/61FrSNB6r0uCKLSYB6jns=";
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
