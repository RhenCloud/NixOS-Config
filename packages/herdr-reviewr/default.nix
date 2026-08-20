{
  lib,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
}:

rustPlatform.buildRustPackage {
  pname = "herdr-reviewr";
  version = "0.33.0";

  src = fetchFromGitHub {
    owner = "persiyanov";
    repo = "herdr-reviewr";
    rev = "e7d88534588f8865b9e14cc65f353596aa571427";
    hash = "sha256-kS40fu57daPBUzUzEojOz2LrGzo90sYpeL3VCZK88X0=";
  };

  cargoHash = "sha256-043nvKhAbASHRVL0/R+DVvZPC4dAv3J+XAnH7HD8b6Q=";

  nativeBuildInputs = [ installShellFiles ];

  doCheck = false;

  postInstall = ''
    mkdir -p $out/share/persiyanov.reviewr/herdr
    mkdir -p $out/share/persiyanov.reviewr/bin

    cp herdr-plugin.toml $out/share/persiyanov.reviewr/
    cp -r herdr/* $out/share/persiyanov.reviewr/herdr/
    ln -s $out/bin/herdr-reviewr $out/share/persiyanov.reviewr/bin/herdr-reviewr
  '';

  meta = {
    description = "A code-review + file-viewer sidebar for herdr";
    homepage = "https://github.com/persiyanov/herdr-reviewr";
    license = lib.licenses.mit;
    mainProgram = "herdr-reviewr";
    platforms = lib.platforms.linux;
  };
}
