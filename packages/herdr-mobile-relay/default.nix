{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.16.4";
  system = stdenvNoCC.hostPlatform.system;
  arch =
    {
      x86_64-linux = "amd64";
      aarch64-linux = "arm64";
      x86_64-darwin = "amd64";
      aarch64-darwin = "arm64";
    }
    .${system} or (throw "unsupported system: ${system}");
  os =
    {
      x86_64-linux = "linux";
      aarch64-linux = "linux";
      x86_64-darwin = "darwin";
      aarch64-darwin = "darwin";
    }
    .${system} or (throw "unsupported system: ${system}");
  binaryHash =
    {
      x86_64-linux = "sha256-YSq7tL+vnjUvrKwTJ4dXO0TDMn4Vii31YVTjIWEwLUU=";
      aarch64-linux = "sha256-Ihaq8lmpPhVDS91OwKtksU3E+wsoMdGQaQuhLc5+DE4=";
      x86_64-darwin = "sha256-zh/g9WxW2olQTSe3BoCupJEAs0NzPY4UFCohmEcv9FQ=";
      aarch64-darwin = "sha256-nEaiLIG5/fEcNb+P5oaCgvgzCfnJk88hsXuoSONxsxE=";
    }
    .${system} or (throw "unsupported system: ${system}");
  binarySrc = fetchurl {
    url = "https://github.com/0cv/herdr-mobile-relay/releases/download/v${version}/herdr-mobile-relay_${version}_${os}_${arch}.tar.gz";
    hash = binaryHash;
  };
in

stdenvNoCC.mkDerivation {
  pname = "herdr-mobile-relay";
  inherit version;

  src = fetchurl {
    url = "https://github.com/0cv/herdr-mobile-relay/archive/refs/tags/v${version}.tar.gz";
    hash = "sha256-JIBgf/7eH01QZ8/AJeXntaa+ngjzsfa3KPGM3zqxlKk=";
  };

  sourceRoot = "herdr-mobile-relay-${version}";

  installPhase = ''
    mkdir -p $out/share/herdr-mobile-relay.events
    cp herdr-plugin.toml $out/share/herdr-mobile-relay.events/
    cp install.sh $out/share/herdr-mobile-relay.events/
    cp -r relay $out/share/herdr-mobile-relay.events/

    mkdir -p _tmp
    tar -xzf ${binarySrc} -C _tmp
    cp _tmp/herdr-mobile-relay $out/share/herdr-mobile-relay.events/
    cp _tmp/release-manifest.json $out/share/herdr-mobile-relay.events/
    rm -rf _tmp

    substituteInPlace $out/share/herdr-mobile-relay.events/relay/install-service.sh \
      --replace-quiet 'chmod +x "$SCRIPT_DIR/herdr-mobile-relay-service.sh"' 'true'
    substituteInPlace $out/share/herdr-mobile-relay.events/relay/install-systemd-user-service.sh \
      --replace-quiet 'chmod +x "$SERVICE_WRAPPER"' 'test -x "$SERVICE_WRAPPER" || chmod +x "$SERVICE_WRAPPER"'
  '';

  meta = {
    description = "Remote mobile control for Herdr: approve and monitor agents from your smartphone";
    homepage = "https://github.com/0cv/herdr-mobile-relay";
    license = lib.licenses.agpl3Plus;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
