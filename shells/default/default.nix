{
  bubblewrap,
  mkShell,
  nixfmt,
  nixos-shell,
  self,
  statix,
  stdenvNoCC,
  ...
}:
mkShell {
  packages = [
    nixfmt
    statix
    nixos-shell
    bubblewrap
    self.packages.${stdenvNoCC.hostPlatform.system}.sandbox
  ];
}
