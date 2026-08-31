{ lib, ... }:
let
  dir = ./.;
  ents = builtins.readDir dir;
  subs = lib.filterAttrs (_: t: t == "directory") ents;
  subMods = lib.mapAttrsToList (n: _: dir + "/${n}/mod.nix") subs;
  flats = lib.mapAttrsToList (n: _: dir + "/${n}") (
    lib.filterAttrs (
      n: t:
      t == "regular"
      && lib.hasSuffix ".nix" n
      && !(lib.elem n [
        "home.nix"
        "nixos.nix"
        "default.nix"
        "lucy.nix"
      ])
    ) ents
  );
in
{
  imports = subMods ++ flats;
}
