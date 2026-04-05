{ ... }:
{
  nixpkgs.overlays = [
    (_self: super: {
      ccid = super.ccid.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          plist="$out/pcsc/drivers/ifd-ccid.bundle/Contents/Info.plist"

          sed -i '/<key>ifdProductID<\/key>/i\
                  <string>0x303A</string>' "$plist"

          sed -i '/<key>ifdFriendlyName<\/key>/i\
                  <string>0x0030</string>' "$plist"

          sed -i '/<key>Copyright<\/key>/i\
                  <string>MeXkey3 CCID Reader (303A:0030)</string>' "$plist"
        '';
      });
    })
  ];
}
