{
  lib,
  fetchFromGitHub,
  rustPlatform,
  cargo-tauri,
  jq,
  moreutils,
  nodejs,
  pkg-config,
  pnpm,
  fetchPnpmDeps,
  pnpmConfigHook,
  libappindicator,
  mpv,
  openssl,
  webkitgtk_4_1,
}:

let
  version = "0.9.9";

  src = fetchFromGitHub {
    owner = "YangYuS8";
    repo = "lwe";
    tag = "v${version}";
    hash = "sha256-BsxedubbWIRQ86I7Q2YmQIGFXHsxJ77Gid54IhvaPxs=";
  };
in
rustPlatform.buildRustPackage {
  pname = "lwe";
  inherit version src;

  # 首次构建时 hash 会报错，用报错输出中的正确 hash 替换即可
  pnpmDeps = fetchPnpmDeps {
    pname = "lwe-pnpm-deps";
    inherit version src;
    fetcherVersion = 3;
    hash = "sha256-QtQfyUDTu7Z/aPmaLwaNOySRWcL3HYZ/h2y582jL2J4=";
  };

  cargoHash = "sha256-LoCy/IWBqOswhmVT7x5nkmzeSzJU04s2rLSx33LF09Q=";

  postPatch = ''
    # 禁用自动更新器（Nix 包不走自更新）
    jq '.bundle.createUpdaterArtifacts = false' \
      src-tauri/tauri.conf.json | sponge src-tauri/tauri.conf.json
  '';

  # libappindicator-sys 通过 libloading 在运行时动态加载 .so，
  # 不走 RPATH，需要手动加入 LD_LIBRARY_PATH
  preFixup = ''
    gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libappindicator mpv ]}")
  '';

  nativeBuildInputs = [
    cargo-tauri.hook
    jq
    moreutils
    nodejs
    pkg-config
    pnpmConfigHook
    pnpm
  ];

  buildInputs = [
    libappindicator
    mpv
    openssl
    webkitgtk_4_1
  ];

  meta = {
    description = "Linux desktop app for browsing, managing, and applying Wallpaper Engine content";
    homepage = "https://github.com/YangYuS8/lwe";
    license = lib.licenses.mit;
    mainProgram = "lwe-shell";
    platforms = lib.platforms.linux;
  };
}
