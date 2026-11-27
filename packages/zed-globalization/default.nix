{
  lib,
  stdenv,
  fetchurl,
  patchelf,

  alsa-lib,
  glib,
  libdrm,
  libGL,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libxcb,
  libxkbcommon,
  mesa,
  pipewire,
  pulseaudio,
  vulkan-loader,
  wayland,
}:

let
  # 原仓库 x6nux/zed-globalization 因作者账号封禁已删除，项目迁移至 x6nux-oss。
  # 旧 URL 全部返回 404，故锁定迁移后的稳定版本。
  version = "1.29.3";

  runtimeLibs = lib.makeLibraryPath [
    alsa-lib
    glib
    libdrm
    libGL
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
    libxkbcommon
    mesa
    pipewire
    pulseaudio
    stdenv.cc.cc.lib
    vulkan-loader
    wayland
  ];
in
stdenv.mkDerivation {
  pname = "zedg";
  inherit version;

  src = fetchurl {
    url = "https://github.com/x6nux-oss/zed-globalization/releases/download/v${version}/zedg-zh-cn-linux-x86_64-v${version}.tar.gz";
    hash = "sha256-utO72iNCFDcwcLdT6pgAmmIBnjTIBWeCmf8RaEu4T2o=";
  };

  nativeBuildInputs = [ patchelf ];

  dontConfigure = true;
  dontBuild = true;

  # tar 只有一个顶层目录 usr/，默认 sourceRoot 会变成它；
  # 换成 "." 以保留 usr/ 前缀，便于后续按完整路径安装。
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    # v1.29 起的 tar 使用 usr/ 前缀（usr/bin、usr/libexec、usr/lib/zedg）
    install -Dm755 usr/bin/zedg $out/bin/zedg
    ln -s zedg $out/bin/zed
    install -Dm755 usr/libexec/zedg $out/libexec/zedg
    install -Dm755 usr/libexec/zed-cli $out/libexec/zed-cli

    # 随包的 libgit2 需与主程序同目录关系保持不变
    if [ -d usr/lib/zedg ]; then
      mkdir -p $out/lib/zedg
      cp -p usr/lib/zedg/* $out/lib/zedg/
    fi

    install -Dm644 usr/share/applications/zedg.desktop $out/share/applications/zedg.desktop
    for icon in usr/share/icons/hicolor/*/apps/zedg.png; do
      size=$(echo "$icon" | sed 's|.*hicolor/\([^/]*\)/.*|\1|')
      install -Dm644 "$icon" "$out/share/icons/hicolor/$size/apps/zedg.png"
    done

    runHook postInstall
  '';

  postFixup = ''
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${runtimeLibs}:$out/lib/zedg" \
      $out/bin/zedg
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${runtimeLibs}:$out/lib/zedg" \
      $out/libexec/zedg
  '';

  meta = {
    description = "Zed Editor Chinese Localization (Zed 编辑器汉化版)";
    homepage = "https://github.com/x6nux/zed-globalization";
    license = lib.licenses.mit;
    mainProgram = "zedg";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
