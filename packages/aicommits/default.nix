{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs,
  pnpm,
  pnpmConfigHook,
  fetchPnpmDeps,
}:

let
  version = "3.4.0";

  src = fetchFromGitHub {
    owner = "nutlope";
    repo = "aicommits";
    rev = "v${version}";
    hash = "sha256-xh7TM3ThajeOXYCj2Vc246u3kYxA1VCHFWM4QbM8DGo=";
  };
in
stdenv.mkDerivation {
  pname = "aicommits";
  inherit version src;

  pnpmDeps = fetchPnpmDeps {
    pname = "aicommits-pnpm-deps";
    inherit version src;
    fetcherVersion = 4;
    hash = "sha256-nEJ7PGfLnpD9xyLk5iPDtFAzi3BQ7CQ+lWJuKieM4jk=";
  };

  nativeBuildInputs = [
    pnpm
    pnpmConfigHook
    nodejs
  ];

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -r dist $out/
    ln -s $out/dist/cli.mjs $out/bin/aicommits
    ln -s $out/dist/cli.mjs $out/bin/aic
    runHook postInstall
  '';

  meta = {
    description = "A CLI that writes your git commit messages for you with AI";
    homepage = "https://github.com/nutlope/aicommits";
    license = lib.licenses.mit;
    mainProgram = "aicommits";
    platforms = lib.platforms.linux;
  };
}
