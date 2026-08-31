{ lib, self }:
let
  root = toString self;
in
lib.cleanSourceWith {
  src = self;
  filter =
    path: _type:
    let
      relative = lib.removePrefix "${root}/" (toString path);
      topLevel = lib.head (lib.splitString "/" relative);
    in
    !builtins.elem topLevel [
      ".git"
      "result"
      "secrets"
      "wallpapers"
    ];
}
