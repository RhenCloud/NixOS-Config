{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.chat;

  qqPackage = pkgs.qq;
  liteLoaderQQNT = inputs.liteloaderqqnt;

  qqWithLiteLoaderPackage = qqPackage.overrideAttrs (previousAttrs: {
    nativeBuildInputs = (previousAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.gnused ];
    postFixup = (previousAttrs.postFixup or "") + ''
            app_dir="$out/opt/QQ/resources/app"
            mkdir -p "$app_dir/app_launcher"
            cat > "$app_dir/app_launcher/LiteLoader.js" <<EOF
      require(String.raw({ raw: ["${liteLoaderQQNT}"] }))
      EOF
            sed -i 's#"main": "./application.asar/app_launcher/index.js"#"main": "./app_launcher/LiteLoader.js"#' "$app_dir/package.json"
    '';
  });

  qqWithLiteLoader = pkgs.writeShellApplication {
    name = "qq";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.xclip
    ];
    text = ''
      set -euo pipefail

      profile_root="''${XDG_DATA_HOME:-$HOME/.local/share}/liteloaderqqnt"

      export LITELOADERQQNT_PROFILE="$profile_root"
      export XDG_SESSION_TYPE=wayland
      export NIXOS_OZONE_WL=1
      export ELECTRON_OZONE_PLATFORM_HINT=wayland
      export GTK_IM_MODULE=fcitx
      export QT_IM_MODULE=fcitx
      export XMODIFIERS='@im=fcitx'
      export SDL_IM_MODULE=fcitx
      export GLFW_IM_MODULE=fcitx
      export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib
      export VIPS_BLOCK_UNTRUSTED=1

      exec ${qqWithLiteLoaderPackage}/bin/qq --ozone-platform=wayland --enable-features=UseOzonePlatform,WaylandWindowDecorations "$@"
    '';
  };
in
{
  options.rhencloud.chat.enable = mkEnableOption "chat apps (QQ, WeChat, Discord)";

  config = mkIf cfg.enable {
    xdg.desktopEntries.qq = {
      name = "QQ";
      comment = "Tencent QQ with LiteLoaderQQNT";
      exec = "qq %U";
      icon = "${qqWithLiteLoaderPackage}/share/icons/hicolor/512x512/apps/qq.png";
      terminal = false;
      categories = [
        "Network"
        "InstantMessaging"
        "Chat"
      ];
    };

    home.packages = with pkgs; [
      (symlinkJoin {
        name = "vesktop-wayland";
        paths = [ vesktop ];
        nativeBuildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/vesktop \
            --set NIXOS_OZONE_WL 1 \
            --set ELECTRON_OZONE_PLATFORM_HINT wayland \
            --add-flags "--enable-features=WebRTCPipeWireCapturer,UseOzonePlatform,WaylandWindowDecorations" \
            --add-flags "--ozone-platform=wayland"
        '';
      })

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
            --set GLFW_IM_MODULE fcitx \
            --prefix PATH : ${lib.makeBinPath [ xclip ]}
        '';
      })
      (symlinkJoin {
        name = "qq-wayland-liteloader";
        paths = [ qqWithLiteLoader ];
        nativeBuildInputs = [ makeWrapper ];
        postBuild = ''
          if [ -x "$out/bin/qq" ] && [ ! -e "$out/bin/linuxqq" ]; then
            ln -s "$out/bin/qq" "$out/bin/linuxqq"
          fi
        '';
      })

      feishu
      # telegram-desktop
      ayugram-desktop
      zoom-us
      thunderbird
      slack
    ];
  };
}
