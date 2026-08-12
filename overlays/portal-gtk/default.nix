_: _final: prev: {
  xdg-desktop-portal-gtk = prev.xdg-desktop-portal-gtk.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      substituteInPlace $out/share/xdg-desktop-portal/portals/gtk.portal \
        --replace-fail "UseIn=gnome" "UseIn=gnome;Hyprland;niri;mangowm"
    '';
  });
}
