{ config, lib, ... }:
with lib;
let
  cfg = config.rhencloud.kitty;
in
{
  options.rhencloud.kitty.enable = mkEnableOption "Kitty terminal";

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      shellIntegration.enableBashIntegration = true;
      enableGitIntegration = true;

      # noctalia 在换壁纸时生成的配色，放在末尾覆盖下方兜底色
      extraConfig = ''
        include themes/noctalia.conf
      '';

      settings = {
        cursor_shape = "beam";
        strip_trailing_spaces = "always";
        enable_audio_bell = "no";
        linux_display_server = "wayland";
        wayland_enable_ime = "yes";
        confirm_os_window_close = 0;
        cursor_trail = 3;
        cursor_trail_decay = "0.1 0.4";
        background = "#282a36";
        foreground = "#f8f8f2";
      };
      keybindings = {
        "ctrl + v" = "paste_from_clipboard";
      };
    };
  };
}
