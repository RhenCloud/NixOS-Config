{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
let
  version = "0.2.0";
in
rustPlatform.buildRustPackage {
  pname = "herdr-spreader";
  inherit version;

  src = fetchFromGitHub {
    owner = "yuk1ty";
    repo = "herdr-spreader";
    rev = "v${version}";
    hash = "sha256-Cb/Tbr+HbUl5nfBbYHhjyJq6x5GLSmXimD9jjI8/qGw=";
  };

  cargoHash = "sha256-PJYF83XM9WhT2HB4mVOArB2cGE8PYe7A3pvF8TD32q0=";

  postInstall = ''
    mkdir -p $out/share/herdr-spreader
    cp ${./herdr-plugin.toml} $out/share/herdr-spreader/herdr-plugin.toml
  '';

  meta = {
    description = "Apply tmuxinator-style project layouts to herdr from a YAML file";
    homepage = "https://github.com/yuk1ty/herdr-spreader";
    license = lib.licenses.mit;
    mainProgram = "herdr-spreader";
    platforms = lib.platforms.linux;
  };
}
