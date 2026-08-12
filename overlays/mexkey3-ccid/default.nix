_: _final: prev: {
  ccid = prev.ccid.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      plist="$out/pcsc/drivers/ifd-ccid.bundle/Contents/Info.plist"

      awk '
        /<key>ifdVendorID<\/key>/     { vid = 1 }
        vid && /<\/array>/            { print "\t\t<string>0x303A</string>"; vid = 0 }
        /<key>ifdProductID<\/key>/    { pid = 1 }
        pid && /<\/array>/            { print "\t\t<string>0x0030</string>"; pid = 0 }
        /<key>ifdFriendlyName<\/key>/ { name = 1 }
        name && /<\/array>/           { print "\t\t<string>MeXkey3 CCID Reader (303A:0030)</string>"; name = 0 }
        { print }
      ' "$plist" > "$plist.tmp" && mv "$plist.tmp" "$plist"
    '';
  });
}
