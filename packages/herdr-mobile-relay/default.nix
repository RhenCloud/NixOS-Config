{
  lib,
  stdenvNoCC,
  fetchurl,
}:

stdenvNoCC.mkDerivation {
  pname = "herdr-mobile-relay";
  version = "0.16.4";

  src = fetchurl {
    url = "https://github.com/0cv/herdr-mobile-relay/archive/refs/tags/v0.16.4.tar.gz";
    hash = "sha256-JIBgf/7eH01QZ8/AJeXntaa+ngjzsfa3KPGM3zqxlKk=";
  };

  sourceRoot = "herdr-mobile-relay-0.16.4";

  installPhase = ''
    mkdir -p $out/share/herdr-mobile-relay.events
    cp herdr-plugin.toml $out/share/herdr-mobile-relay.events/
    cp install.sh $out/share/herdr-mobile-relay.events/
    cp -r relay $out/share/herdr-mobile-relay.events/
  '';

  meta = {
    description = "Remote mobile control for Herdr: approve and monitor agents from your smartphone";
    homepage = "https://github.com/0cv/herdr-mobile-relay";
    license = lib.licenses.agpl3Plus;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}