{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.hm-niri;

  mousePassthroughPatch = ../../../../patches/niri/mouse-passthrough.patch;
  pinPatch = ../../../../patches/niri/pin.patch;

  niri-patched =
    inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable.overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [
          mousePassthroughPatch
          pinPatch
        ];
      });
in
{
  options.rhencloud.hm-niri.enable = mkEnableOption "Niri (HM)";

  config = mkIf cfg.enable {
    programs.niri = {
      enable = true;
      package = niri-patched;
    };

    home.packages = [
      inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.xwayland-satellite-unstable
      pkgs.nirius
    ];
    sops.secrets."sleepy-token" = {
      sopsFile = ../../../../secrets/common.yaml;
    };

    sops.templates."piri.toml" = {
      mode = "0400";
      content = ''
        [niri]

        [piri.plugins]
        scratchpads = true
        empty = false
        window_rule = true
        autofill = true
        singleton = true
        window_order = true
        swallow = true
        workspace_rule = true
        fcitx5 = true
        sleepy = true

        [piri.scratchpad]
        default_size = "40% 60%"
        default_margin = 50

        [scratchpads.musicfox]
        direction = "fromTop"
        command = "kitty --class musicfox musicfox"
        app_id = "float.musicfox"
        size = "60% 40%"
        margin = 150

        [empty.1]
        command = "vesktop ; zen ; linuxqq"

        [empty.2]
        command = "kitty"

        [sleepy]
        server_url = "https://sleepy.rhen.cloud"
        # server_url = "https://sleepy-eo.rhen.cloud"
        device_id = "nixos-desktop"
        device_name = "NixOS Desktop"
        token = "${config.sops.placeholder."sleepy-token"}"
        secret = ""
        prefer_app_id = false

        media_process_name = "splayer|musicfox"
        media_device_id = "nixos-desktop-media"
        media_device_name = "NixOS-Desktop Media"
        media_poll_interval = 5

        [[fcitx5]]
        app_id = "zen"
        input_mode = "english"

        [[fcitx5]]
        app_id = "kitty"
        input_mode = "english"

        [[fcitx5]]
        app_id = "code"
        input_mode = "english"

        [[fcitx5]]
        app_id = "QQ"
        input_mode = "chinese"

        [[fcitx5]]
        app_id = "wechat"
        input_mode = "chinese"

        [[fcitx5]]
        app_id = "vesktop"
        input_mode = "chinese"

        [[fcitx5]]
        app_id = "dev.zed.Zed"
        input_mode = "english"
      '';
    };

    xdg.configFile = {
      "niri/autostart.kdl".source = ./niri/autostart.kdl;
      "niri/config.kdl".source = ./niri/config.kdl;
      "niri/dracula.kdl".source = ./niri/dracula.kdl;
      "niri/env.kdl".source = ./niri/env.kdl;
      "niri/input.kdl".source = ./niri/input.kdl;
      "niri/keys.kdl".source = ./niri/keys.kdl;
      "niri/rule.kdl".source = ./niri/rule.kdl;
      "niri/piri.toml".source =
        config.lib.file.mkOutOfStoreSymlink
          config.sops.templates."piri.toml".path;
      "niri_tweaks" = {
        source = inputs.niri_tweaks;
      };
    };

    programs.piri = {
      enable = true;
      enableFishIntegration = true;
      package = inputs.piri.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
  };
}
