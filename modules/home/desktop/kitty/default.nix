{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "Maple Mono NF CN";
      size = 11.0;
      package = pkgs.maple-mono.NF-CN;
    };
    shellIntegration.enableBashIntegration = true;
    enableGitIntegration = true;
    themeFile = "Dracula";
    settings = {
      background_opacity = 0.75;
      cursor_shape = "beam";
      strip_trailing_spaces = "always";
      enable_audio_bell = "no";
      linux_display_server = "wayland";
      wayland_enable_ime = "yes";
    };
    keybindings = {
      "ctrl + v" = "paste_from_clipboard";
    };
  };
}
