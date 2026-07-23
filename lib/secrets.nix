{ lib, inputs, ... }:
let
  inherit (lib.strings) trim;
in {
  read = path: trim (builtins.readFile "${inputs.self}/secrets/${path}");
}
