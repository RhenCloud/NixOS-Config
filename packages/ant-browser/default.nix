{
  lib,
  stdenv,
  fetchurl,
  unzip,
  gnutar,
  gzip,
  makeWrapper,
  gtk3,
  glib,
  gsettings-desktop-schemas,
  webkitgtk_4_1,
  libayatana-appindicator,
  libsoup_3,
  gdk-pixbuf,
  pango,
  cairo,
  atk,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxkbcommon,
  nss,
  nspr,
  cups,
  alsa-lib,
  dbus,
  libdrm,
  libgbm,
  mesa,
  udev,
  at-spi2-core,
  expat,
}:

stdenv.mkDerivation {
  pname = "ant-browser";
  version = "1.8.0";

  src = fetchurl {
    url = "https://github.com/black-ant/Ant-Browser/releases/download/V1.8.0/ant-browser-linux-amd64.zip";
    hash = "sha256-eapaUef9MOqfeD4PjVOrSdPmMCQwVvjRS49Aokz2bSU=";
  };

  nativeBuildInputs = [
    unzip
    gnutar
    gzip
    makeWrapper
  ];

  buildInputs = [
    gtk3
    webkitgtk_4_1
    libayatana-appindicator
    libsoup_3
    glib
    gsettings-desktop-schemas
    gdk-pixbuf
    pango
    cairo
    atk
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxkbcommon
    nss
    nspr
    cups
    alsa-lib
    dbus
    libdrm
    libgbm
    mesa
    udev
    at-spi2-core
    expat
  ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    unzip -q "$src" -d unpacked
    mkdir -p "$out/bin/bin" "$out/share/ant-browser"
    tar -xzf unpacked/AntBrowser-1.8.0-linux-amd64.tar.gz \
      -C "$out/share/ant-browser"

    install -Dm755 "$out/share/ant-browser/ant-chrome" "$out/libexec/ant-browser/ant-chrome"
    install -Dm644 "$out/share/ant-browser/config.yaml" "$out/libexec/ant-browser/config.yaml"
    install -Dm755 "$out/share/ant-browser/bin/xray" "$out/libexec/ant-browser/bin/xray"
    install -Dm755 "$out/share/ant-browser/bin/sing-box" "$out/libexec/ant-browser/bin/sing-box"
    install -d "$out/libexec/ant-browser/data" "$out/libexec/ant-browser/chrome"

    tar -xJf ${fetchurl {
      url = "https://github.com/adryfish/fingerprint-chromium/releases/download/150.0.7871.186/ungoogled-chromium-150.0.7871.186-1-x86_64_linux.tar.xz";
      hash = "sha256-SO/4YAU+/ZrUmNUTcPCh9Z+YPfOcAqcq0qhoLN6tQFU=";
    }} \
      -C "$out/libexec/ant-browser/chrome" --strip-components=1
    chmod -R u+rwX,go+rX "$out/libexec/ant-browser/chrome"
    mv "$out/libexec/ant-browser/chrome/chrome" "$out/libexec/ant-browser/chrome/chrome-bin"
    substituteInPlace "$out/libexec/ant-browser/chrome/chrome-wrapper" \
      --replace-fail '"$HERE/chrome"' '"$HERE/chrome-bin"'
    makeWrapper "$out/libexec/ant-browser/chrome/chrome-wrapper" "$out/libexec/ant-browser/chrome/chrome" \
      --chdir "$out/libexec/ant-browser/chrome" \
      --set CHROME_WRAPPER "$out/libexec/ant-browser/chrome/chrome-wrapper" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
        gtk3
        glib
        gdk-pixbuf
        pango
        cairo
        atk
        webkitgtk_4_1
        libayatana-appindicator
        libsoup_3
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        libxkbcommon
        nss
        nspr
        cups
        alsa-lib
        dbus
        libdrm
        libgbm
        mesa
        udev
        at-spi2-core
        expat
      ]}

    rm -rf "$out/share/ant-browser/ant-chrome" \
      "$out/share/ant-browser/config.yaml" \
      "$out/share/ant-browser/bin" \
      "$out/share/ant-browser/data"

    makeWrapper "$out/libexec/ant-browser/ant-chrome" "$out/bin/ant-chrome" \
      --chdir "$out/libexec/ant-browser" \
      --set GSETTINGS_SCHEMA_DIR "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}/glib-2.0/schemas" \
      --prefix XDG_DATA_DIRS : "${gsettings-desktop-schemas}/share" \
      --set ANT_BROWSER_CHROME_PATH "$out/libexec/ant-browser/chrome/chrome" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
        gtk3
        glib
        gdk-pixbuf
        pango
        cairo
        atk
        webkitgtk_4_1
        libayatana-appindicator
        libsoup_3
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        libxkbcommon
        nss
        nspr
        cups
        alsa-lib
        dbus
        libdrm
        libgbm
        mesa
        udev
        at-spi2-core
        expat
      ]}

    install -Dm644 ${./ant-browser.desktop} "$out/share/applications/ant-browser.desktop"

    runHook postInstall
  '';

  meta = {
    description = "多账号隔离、代理绑定和本地环境管理的桌面浏览器工具";
    homepage = "https://github.com/black-ant/Ant-Browser";
    license = lib.licenses.mit;
    mainProgram = "ant-chrome";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
