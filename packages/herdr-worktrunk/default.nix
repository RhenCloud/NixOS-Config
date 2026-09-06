{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "herdr-worktrunk";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "devashish2203";
    repo = "herdr-worktrunk";
    rev = "9cde723b7c6ea5d3f4de94760888de0e4090727b";
    hash = "sha256-Tx++zTQ1z4H8dLdCjOZ1yX9QGY/i6M3Yvi39KGHDoH4=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/worktrunk"
    cp herdr-plugin.toml config.sh helpers.sh lifecycle.sh merge.sh open.sh picker.sh remove.sh \
      "$out/share/worktrunk/"

    runHook postInstall
  '';

  meta = {
    description = "Herdr plugin for git worktrees via worktrunk";
    homepage = "https://github.com/devashish2203/herdr-worktrunk";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
