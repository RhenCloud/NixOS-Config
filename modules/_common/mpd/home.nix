{ lib, config, ... }:
with lib;
let
  cfg = config.rhencloud.mpd;
in
{
  options.rhencloud.mpd.enable = mkEnableOption "MPD music daemon";
  config = mkIf cfg.enable {
    services.mpd = {
      enable = true;
      musicDirectory = "${config.home.homeDirectory}/Music";
      extraConfig = ''
        audio_output {
          type "pipewire"
          name "PipeWire Output"
          format "48000:16:2"
        }

        # 网易云 CDN 错误地把 FLAC 流标注为 audio/mpeg，
        # 导致 MPD 选择 mpg123/mad 解码 FLAC 失败产生电流音。
        # 禁用 mp3 专用解码器，强制使用 ffmpeg 自动探测真实格式。
        decoder {
          plugin "mad"
          enabled "no"
        }
        decoder {
          plugin "mpg123"
          enabled "no"
        }
      '';

      # user = "userRunningPipeWire";

      # Optional:
      network.listenAddress = "any"; # if you want to allow non-localhost connections
      network.startWhenNeeded = true; # systemd feature: only start MPD service upon connection to its socket
    };

    # systemd.services.mpd.environment = {
    #   # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/609
    #   XDG_RUNTIME_DIR = "/run/user/${toString config.users.users.userRunningPipeWire.uid}"; # User-id must match above user. MPD will look inside this directory for the PipeWire socket.
    # };
  };
}
