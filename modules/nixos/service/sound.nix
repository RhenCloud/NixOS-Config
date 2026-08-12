{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.sound;
in
{
  options.rhencloud.sound.enable = mkEnableOption "sound (PipeWire)";

  config = mkIf cfg.enable {
    services = {
      pulseaudio.enable = false;
      udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ENV{ID_USB_INTERFACES}=="*:01*:*", ATTR{power/control}="on"
      '';
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber = {
          enable = true;
          extraConfig = {
            bluetoothEnhancements = {
              "monitor.bluez.properties" = {
                "bluez5.enable-sbc-xq" = true;
                "bluez5.enable-msbc" = true;
                "bluez5.enable-hw-volume" = false;
                "bluez5.codecs" = [
                  "aac"
                  "ldac"
                  "aptx"
                  "aptx_hd"
                ];
                "bluez5.roles" = [
                  "hsp_hs"
                  "hsp_ag"
                  "hfp_hf"
                  "hfp_ag"
                ];
              };
            };
            alsaRules = {
              "monitor.alsa.rules" = [
                {
                  matches = [
                    { "device.name" = "~alsa_output.*"; }
                  ];
                  actions = {
                    update-props = {
                      "session.suspend-timeout-seconds" = 0;
                    };
                  };
                }
                {
                  matches = [
                    {
                      "device.bus" = "usb";
                    }
                  ];
                  actions = {
                    update-props = {
                      "api.alsa.soft-mixer" = true;
                    };
                  };
                }
              ];
            };
          };
        };
      };
    };

    security.rtkit.enable = true;

    systemd.user.services.pipewire-pulse = {
      serviceConfig.LimitNOFILE = 65536;
    };

    systemd.user.services.virtual-mic = {
      enable = true;
      description = "Virtual microphone for system audio capture";
      after = [
        "pipewire-pulse.service"
        "pipewire-pulse.socket"
      ];
      bindsTo = [ "pipewire-pulse.service" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "no";
      };
      script = ''
        PACTL=${pkgs.pulseaudio}/bin/pactl
        TIMEOUT=${pkgs.coreutils}/bin/timeout

        for i in $(seq 1 20); do
          $TIMEOUT 2 $PACTL info >/dev/null 2>&1 && break
          sleep 1
        done

        for mod in $($PACTL list modules short 2>/dev/null | awk '\$2=="module-null-sink" || \$2=="module-loopback" || \$2=="module-virtual-source" {print \$1}'); do
          $PACTL unload-module "$mod" 2>/dev/null || true
        done

        $PACTL load-module module-null-sink \
          sink_name=system_audio \
          sink_properties="device.description=SystemAudio"

        $PACTL load-module module-loopback \
          source='@DEFAULT_SINK@.monitor' \
          sink=system_audio \
          latency_msec=10

        $PACTL load-module module-virtual-source \
          source_name=VirtualMic \
          source_properties="device.description=VirtualMic" \
          master=system_audio.monitor

        $PACTL set-source-volume output.VirtualMic 100%
      '';
    };
  };
}
