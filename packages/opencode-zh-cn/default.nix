{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
}:
let
  version = "8.7.0";
in
stdenv.mkDerivation {
  pname = "opencode-zh-cn";
  inherit version;

  src = fetchurl {
    url = "https://github.com/1186258278/OpenCodeChineseTranslation/releases/download/v${version}/opencode-zh-CN-v${version}-linux-x64.zip";
    hash = "sha256-VEnLFyW48FCX+nMmKXjigjD2wGkfTcR/e1qQd9epV/g=";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
  ];

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 opencode $out/bin/opencode
    runHook postInstall
  '';

  meta = {
    description = "OpenCode 中文汉化版";
    homepage = "https://github.com/1186258278/OpenCodeChineseTranslation";
    license = lib.licenses.mit;
    mainProgram = "opencode";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
