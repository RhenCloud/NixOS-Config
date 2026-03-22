{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      ccid = prev.ccid.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          plist="$out/etc/libccid_Info.plist"

          if [ -f "$plist" ] && ! grep -q 'MeXkey3' "$plist"; then
            sed -i -e '/<key>ifdVendorID<\/key>/{n;a \ \t\t<string>0x303A</string>'$'\n''}' "$plist"
            sed -i -e '/<key>ifdProductID<\/key>/{n;a \ \t\t<string>0x0030</string>'$'\n''}' "$plist"
            sed -i -e '/<key>ifdFriendlyName<\/key>/{n;a \ \t\t<string>MeXkey3</string>'$'\n''}' "$plist"
          fi
        '';
      });
    })
  ];
}
