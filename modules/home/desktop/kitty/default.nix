{
  ...
}:

{

  # imports = [
  #   ./dracula.nix
  # ];

  xdg.configFile."kitty/Dracula.conf".source = ./Dracula.conf;

  programs.kitty = {
    enable = true;
    font = {
      name = "Maple Mono NF CN";
      size = 11.0;
      # package = pkgs.maple-mono.NF-CN;
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
      confirm_os_window_close = 0;
      cursor_trail = 3;
      cursor_trail_decay = "0.1 0.4";
    };
    keybindings = {
      "ctrl + v" = "paste_from_clipboard";
    };
  };
}
