{
  lib,
  stdenvNoCC,
  inputs,
}:

stdenvNoCC.mkDerivation {
  pname = "ttt-herdr-plugin";
  version = inputs.ttt.shortRev or "dev";
  src = inputs.ttt;

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/ttt.editor"
    cp -r herdr-plugin/herdr-plugin.toml herdr-plugin/scripts "$out/share/ttt.editor/"
    chmod +x "$out/share/ttt.editor/scripts/"*.sh

    runHook postInstall
  '';

  meta = {
    description = "Herdr plugin for the TTT terminal editor";
    homepage = "https://github.com/eugenioenko/ttt";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
