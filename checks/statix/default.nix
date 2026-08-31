{
  lib,
  runCommand,
  self,
  statix,
  ...
}:
let
  source = import ../source.nix { inherit lib self; };
in
runCommand "check-statix" { } ''
  cd ${source}
  ${statix}/bin/statix check .
  touch $out
''
