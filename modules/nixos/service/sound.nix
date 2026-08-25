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
                  "a2dp_sink"
                  "a2dp_source"
                  "bap_sink"
                  "bap_source"
                  "hfp_ag"
                  "hsp_ag"
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
        extraConfig.pipewire."90-surround-loopback" = {
          "context.objects" = [
            {
              factory = "adapter";
              args = {
                "factory.name" = "support.null-audio-sink";
                "node.name" = "surround_master";
                "node.description" = "环绕立体声（USB 前置 + 3.5mm 后置）";
                "media.class" = "Audio/Sink";
                "audio.channels" = 4;
                "audio.position" = [
                  "FL"
                  "FR"
                  "RL"
                  "RR"
                ];
              };
            }
          ];
          "context.modules" = [
            {
              name = "libpipewire-module-loopback";
              args = {
                "node.description" = "前置 USB";
                "capture.props" = {
                  "node.name" = "capture.usb_front";
                  "stream.capture.sink" = true;
                  "target.object" = "surround_master";
                  "audio.position" = [
                    "FL"
                    "FR"
                  ];
                  "stream.dont-remix" = true;
                  "node.passive" = true;
                };
                "playback.props" = {
                  "node.name" = "playback.usb_front";
                  "target.object" = "alsa_output.usb-EDIFIER_EDIFIER_R20_415035303039340E-00.analog-stereo";
                  "audio.position" = [
                    "FL"
                    "FR"
                  ];
                  "stream.dont-remix" = true;
                };
              };
            }
            {
              name = "libpipewire-module-loopback";
              args = {
                "node.description" = "后置 3.5mm";
                "target.delay.sec" = 0.16;
                "capture.props" = {
                  "node.name" = "capture.onboard_rear";
                  "stream.capture.sink" = true;
                  "target.object" = "surround_master";
                  "audio.position" = [
                    "RL"
                    "RR"
                  ];
                  "stream.dont-remix" = true;
                  "node.passive" = true;
                };
                "playback.props" = {
                  "node.name" = "playback.onboard_rear";
                  "target.object" = "alsa_output.pci-0000_00_1b.0.analog-stereo";
                  "audio.position" = [
                    "FL"
                    "FR"
                  ];
                  "stream.dont-remix" = true;
                };
              };
            }
          ];
        };
        extraConfig.client."90-upmix-stereo" = {
          "stream.properties" = {
            "channelmix.upmix" = true;
            "channelmix.upmix-method" = "simple";
          };
        };
        extraConfig.pipewire-pulse."90-upmix-stereo" = {
          "stream.properties" = {
            "channelmix.upmix" = true;
            "channelmix.upmix-method" = "simple";
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
