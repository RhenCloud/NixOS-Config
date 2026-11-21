{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libGL,
  libpulseaudio,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  systemd,
  wayland,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxshmfence,
  libxtst,
  adwaita-icon-theme,
  gsettings-desktop-schemas,
  xdg-utils,
  freefont_ttf,
  ipafont,
  liberation_ttf,
  noto-fonts,
  noto-fonts-cjk-sans,
  noto-fonts-color-emoji,
  tlwg,
  unifont,
  wqy_zenhei,
  makeFontsConf,
}:

let
  version = "146.0.7680.177.5";
  runtimeLibraries = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libGL
    libpulseaudio
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd
    wayland
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxscrnsaver
    libxshmfence
    libxtst
  ];
  desktopLibraries = [
    adwaita-icon-theme
    gsettings-desktop-schemas
    xdg-utils
  ];
  fonts = [
    freefont_ttf
    ipafont
    liberation_ttf
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    tlwg
    unifont
    wqy_zenhei
  ];
  fontsConf = makeFontsConf { fontDirectories = fonts; };
in
stdenvNoCC.mkDerivation {
  pname = "cloakbrowser-chromium";
  inherit version;

  src = fetchurl {
    url = "https://cloakbrowser.dev/chromium-v${version}/cloakbrowser-linux-x64.tar.gz";
    hash = "sha256-ShK83pX6G7G+7ytBq15cJ8Nr544749DayMZNcFIWZw4=";
  };

  dontUnpack = true;
  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = runtimeLibraries ++ desktopLibraries;
  runtimeDependencies = runtimeLibraries;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/cloakbrowser" "$out/bin"
    tar -xzf "$src" -C "$out/lib/cloakbrowser"
    chmod +x "$out/lib/cloakbrowser/chrome" "$out/lib/cloakbrowser/chromedriver"

    runHook postInstall
  '';

  postFixup = ''
    makeWrapper "$out/lib/cloakbrowser/chrome" "$out/bin/cloakbrowser-chrome" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibraries}" \
      --set GSETTINGS_SCHEMA_DIR "${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}/glib-2.0/schemas" \
      --prefix XDG_DATA_DIRS : "${gsettings-desktop-schemas}/share:${adwaita-icon-theme}/share" \
      --suffix PATH : "${lib.makeBinPath [ xdg-utils ]}" \
      --set FONTCONFIG_FILE "${fontsConf}" \
      --set CHROME_WRAPPER "cloakbrowser-chrome"

    makeWrapper "$out/lib/cloakbrowser/chromedriver" "$out/bin/cloakbrowser-chromedriver" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibraries}"
  '';

  meta = {
    description = "CloakBrowser source-patched Chromium browser binary";
    homepage = "https://github.com/CloakHQ/CloakBrowser";
    license = {
      shortName = "cloakbrowser-binary";
      fullName = "CloakBrowser Binary License";
      url = "https://github.com/CloakHQ/CloakBrowser/blob/main/BINARY-LICENSE.md";
      free = false;
      redistributable = false;
    };
    mainProgram = "cloakbrowser-chrome";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
