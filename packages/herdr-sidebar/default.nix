{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage {
  pname = "herdr-sidebar";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "alexarthurs";
    repo = "herdr-sidebar";
    rev = "dd5cc28aeae5860cffc11080c7613bf829286c72";
    hash = "sha256-jN30nr3NlblL/6wvvIQHMWXikxfGeSZTNxYRxIise1s=";
  };

  sourceRoot = "source/plugins/herdr-sidebar";

  cargoHash = "sha256-sPc9LpQw5Lxc2OuVp4d4UCQP4RF8MUWKHiLKtoUfagw=";

  doCheck = false;

  postInstall = ''
    mkdir -p $out/share/herdr-sidebar/scripts
    mkdir -p $out/share/herdr-sidebar/target/release

    cp $src/plugins/herdr-sidebar/herdr-plugin.toml $out/share/herdr-sidebar/
    cp -r $src/plugins/herdr-sidebar/scripts/* $out/share/herdr-sidebar/scripts/
    ln -s $out/bin/herdr-sidebar $out/share/herdr-sidebar/target/release/herdr-sidebar
    chmod +x $out/share/herdr-sidebar/scripts/*.sh
  '';

  meta = {
    description = "VS Code-style sidebar: file explorer + source control in one herdr pane";
    homepage = "https://github.com/alexarthurs/herdr-sidebar";
    license = lib.licenses.mit;
    mainProgram = "herdr-sidebar";
    platforms = lib.platforms.linux;
  };
}
