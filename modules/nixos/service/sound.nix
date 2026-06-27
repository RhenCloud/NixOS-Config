{ pkgs, ... }:
{
  services.pulseaudio.enable = false; # Use Pipewire, the modern sound subsystem

  security.rtkit.enable = true; # Enable RealtimeKit for audio purposes

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    # jack.enable = true;
    wireplumber.enable = true;
    wireplumber.extraConfig.bluetoothEnhancements = {
      "10-bluez" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          # Keep volume scaling on the host side to avoid low-volume dead zones
          # on some Bluetooth devices (e.g. near 20-30% becoming effectively mute).
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
    };
    wireplumber.extraConfig.usbAlsaSoftMixer = {
      "20-usb-alsa-soft-mixer" = {
        "monitor.alsa.rules" = [
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

  systemd.user.services.system-audio-virtual-mic = {
    enable = true;
    description = "虚拟麦克风 — 捕获系统音频供 Discord 直播使用";
    after = [ "pipewire-pulse.service" ];
    wantedBy = [ "default.target" ];
    script = ''
      ${pkgs.pulseaudio}/bin/pactl load-module module-null-sink \
        sink_name=system_audio \
        sink_properties="device.description=SystemAudio"
      ${pkgs.pulseaudio}/bin/pactl load-module module-loopback \
        source=@DEFAULT_SINK@.monitor \
        sink=system_audio \
        latency_msec=1
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
