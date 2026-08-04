{ }: _final: prev:
let
  version = "4.1.1.4";
  src = prev.fetchurl {
    url = "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage";
    hash = "sha256-RX26ArkbAxzdRBLu4HT7v/udnQax5Q/Bgi00hw4RSZA=";
  };
  appimageContents = prev.appimageTools.extract {
    pname = "wechat";
    inherit version src;
    postExtract = ''
      patchelf --replace-needed libtiff.so.5 libtiff.so $out/opt/wechat/wechat
    '';
  };
in
{
  wechat = prev.appimageTools.wrapAppImage {
    pname = "wechat";
    inherit version;
    meta = prev.wechat.meta;
    src = appimageContents;

    extraInstallCommands = ''
      mkdir -p $out/share/applications
      cp ${appimageContents}/wechat.desktop $out/share/applications/
      mkdir -p $out/share/icons/hicolor/256x256/apps
      cp ${appimageContents}/wechat.png $out/share/icons/hicolor/256x256/apps/

      substituteInPlace $out/share/applications/wechat.desktop --replace-fail AppRun wechat
    '';
  };
}
