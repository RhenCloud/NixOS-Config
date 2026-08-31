{
  lib,
  nixfmt,
  runCommand,
  self,
  ...
}:
let
  source = import ../source.nix { inherit lib self; };
in
runCommand "check-formatting" { } ''
  mapfile -t files < <(find ${source} -name '*.nix' -type f | sort)
  ${nixfmt}/bin/nixfmt --check "''${files[@]}"
  touch $out
''
