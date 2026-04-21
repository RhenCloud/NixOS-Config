{
  pkgs,
  ...
}:
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
      name = "qq-wayland";
      paths = [ qq ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        if [ -x "$out/bin/linuxqq" ] && [ ! -e "$out/bin/qq" ]; then
          ln -s "$out/bin/linuxqq" "$out/bin/qq"
        fi

        wrapProgram $out/bin/qq \
          --set XDG_SESSION_TYPE wayland \
          --set NIXOS_OZONE_WL 1 \
          --set ELECTRON_OZONE_PLATFORM_HINT wayland \
          --set GTK_IM_MODULE fcitx \
          --set QT_IM_MODULE fcitx \
          --set XMODIFIERS @im=fcitx \
          --set SDL_IM_MODULE fcitx \
          --set GLFW_IM_MODULE fcitx \
          --set LD_LIBRARY_PATH ${pkgs.stdenv.cc.cc.lib}/lib \
          --set VIPS_BLOCK_UNTRUSTED 1 \
          --add-flags "--ozone-platform=wayland --enable-features=UseOzonePlatform,WaylandWindowDecorations"
      '';
    })

    feishu

    telegram-desktop
    ayugram-desktop

    zoom-us

    thunderbird
  ];
}
