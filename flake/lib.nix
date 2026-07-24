{ inputs, lib, ... }:
let
  inherit (lib.strings) trim;
in
{
  flake.lib = {
    readSecret = path: trim (builtins.readFile "${inputs.self}/secrets/${path}");
  };
}