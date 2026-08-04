{ config, lib, ... }:
with lib;
let cfg = config.rhencloud.kitty;
in {
  options.rhencloud.kitty.enable = mkEnableOption "Kitty terminal";

  config = mkIf cfg.enable {
    xdg.configFile."kitty/Dracula.conf".source = ./Dracula.conf;

    programs.kitty = {
      enable = true;
      shellIntegration.enableBashIntegration = true;
      enableGitIntegration = true;
      themeFile = "Dracula";
      settings = {
        cursor_shape = "beam";
        strip_trailing_spaces = "always";
        enable_audio_bell = "no";
        linux_display_server = "wayland";
        wayland_enable_ime = "yes";
        confirm_os_window_close = 0;
        cursor_trail = 3;
        cursor_trail_decay = "0.1 0.4";
      };
      keybindings = {
        "ctrl + v" = "paste_from_clipboard";
      };
    };
  };
}
