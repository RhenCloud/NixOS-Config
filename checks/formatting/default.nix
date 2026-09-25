{
  lib,
  nixfmt,
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
runCommand "check-formatting" { } ''
  mapfile -t files < <(find ${source} -name '*.nix' -type f | sort)
  ${nixfmt}/bin/nixfmt --check "''${files[@]}"
  touch $out
''
