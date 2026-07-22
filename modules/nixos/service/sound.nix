{ pkgs, ... }:
{
  services.pulseaudio.enable = false; # Use Pipewire, the modern sound subsystem

  security.rtkit.enable = true; # Enable RealtimeKit for audio purposes

  # Disable USB autosuspend for all USB audio devices. Without this the kernel
  # periodically suspends USB speakers (e.g. Edifier R20), causing the audio
  # output to temporarily disappear / reconnect — particularly noticeable
  # during Discord/Vesktop streams.
  #
  # Note: we match on ID_USB_INTERFACES (device-level env var) instead of
  # bInterfaceClass (interface-level attr) because power/control only exists
  # on the USB device, not on individual interfaces.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ENV{ID_USB_INTERFACES}=="*:01*:*", ATTR{power/control}="on"
  '';

  # pipewire-pulse 的默认 soft limit 仅有 1024，频繁 pactl load-module 容易 EMFILE。
  systemd.user.services.pipewire-pulse = {
    serviceConfig.LimitNOFILE = 65536;
  };

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
    # Prevent ALSA sinks from being suspended on idle — without this,
    # WirePlumber periodically suspends/resumes the audio device, which
    # manifests as brief audio dropouts during Discord streams.
    wireplumber.extraConfig.disableSuspend = {
      "10-disable-suspend" = {
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
        ];
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

  # 虚拟麦克风 — 捕获系统音频供 Discord 使用
  systemd.user.services.virtual-mic = {
    enable = true;
    description = "虚拟麦克风 — 捕获系统音频供 Discord 使用";
    after = [ "pipewire-pulse.service" "pipewire-pulse.socket" ];
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

      # 等待 pipewire-pulse 就绪（带超时防止 pactl 无限阻塞）
      for i in $(seq 1 20); do
        $TIMEOUT 2 $PACTL info >/dev/null 2>&1 && break
        sleep 1
      done

      # 清理旧模块，防止重复加载导致 EMFILE 或 source 冲突
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

      # VirtualMic 默认音量只有 ~69%，设为 100% 避免音损
      # 注意：PipeWire 下 module-virtual-source 将 source 命名为 output.<source_name>
      $PACTL set-source-volume output.VirtualMic 100%
    '';
  };
}
