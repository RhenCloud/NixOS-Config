_:
_final: prev: {
  niri = prev.niri.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      ../../patches/niri/mouse-passthrough.patch
      ../../patches/niri/pin.patch
    ];
  });
}
