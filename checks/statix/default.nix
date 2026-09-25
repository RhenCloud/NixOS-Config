{
  lib,
  runCommand,
  snowveil,
  statix,
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
runCommand "check-statix" { } ''
  cd ${source}
  ${statix}/bin/statix check .
  touch $out
''
