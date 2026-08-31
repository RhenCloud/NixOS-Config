{
  deadnix,
  lib,
  runCommand,
  self,
  ...
}:
let
  source = import ../source.nix { inherit lib self; };
in
runCommand "check-deadnix" { } ''
  ${deadnix}/bin/deadnix --fail -L ${source}
  touch $out
''
