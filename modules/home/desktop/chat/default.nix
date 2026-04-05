{
  pkgs,
  inputs,
  ...
}:
let
  stablePkgs = import inputs.nixpkgs-stable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
in
{
  home.packages = with pkgs; [
    discord

    (symlinkJoin {
      name = "wechat-wayland";
      paths = [ wechat ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/wechat \
          --set XDG_SESSION_TYPE wayland \
          --set NIXOS_OZONE_WL 1 \
          --set ELECTRON_OZONE_PLATFORM_HINT wayland \
          --set GTK_IM_MODULE fcitx \
          --set QT_IM_MODULE fcitx \
          --set XMODIFIERS @im=fcitx \
          --set SDL_IM_MODULE fcitx \
          --set GLFW_IM_MODULE fcitx
      '';
    })
    (symlinkJoin {
      name = "qq-xwayland";
      paths = [ qq ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        if [ -x "$out/bin/linuxqq" ] && [ ! -e "$out/bin/qq" ]; then
          ln -s "$out/bin/linuxqq" "$out/bin/qq"
        fi

        wrapProgram $out/bin/qq \
          --set XDG_SESSION_TYPE x11 \
          --set NIXOS_OZONE_WL 0 \
          --set ELECTRON_OZONE_PLATFORM_HINT x11 \
          --set GTK_IM_MODULE fcitx \
          --set QT_IM_MODULE fcitx \
          --set XMODIFIERS @im=fcitx \
          --set SDL_IM_MODULE fcitx \
          --set GLFW_IM_MODULE fcitx \
          --set LD_LIBRARY_PATH ${stablePkgs.stdenv.cc.cc.lib}/lib \
          --set VIPS_BLOCK_UNTRUSTED 1 \
          --add-flags "--ozone-platform=x11 --disable-features=WaylandWindowDecorations"
      '';
    })

    feishu

    telegram-desktop
    ayugram-desktop

    zoom-us
  ];
}
