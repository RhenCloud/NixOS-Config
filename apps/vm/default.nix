{ nixos-shell, writeShellScriptBin, ... }:
let
  script = writeShellScriptBin "vm" ''
    config="''${1:-${toString ../../vm.nix}}"
    exec ${nixos-shell}/bin/nixos-shell "''${config}"
  '';
in
{
  type = "app";
  program = "${script}/bin/vm";
}
