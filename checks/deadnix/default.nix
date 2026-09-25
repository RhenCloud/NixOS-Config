{
  deadnix,
  lib,
  runCommand,
  snowveil,
  ...
}:
let
  source = snowveil.source.clean {
    excludes = [
      "secrets"
      "wallpapers"
    ];
  };
in
runCommand "check-deadnix" { } ''
  ${deadnix}/bin/deadnix --fail -L ${source}
  touch $out
''
