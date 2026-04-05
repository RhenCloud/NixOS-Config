{
  ...
}:

{
  xdg.configFile."zellij/layouts/default.kdl".source = ./default.kdl;

  programs.zellij = {
    enable = true;
    enableFishIntegration = false;

    settings = {
      # Use a stable symlink instead of /nix/store path to avoid stale shell path in long-lived sessions.
      default_shell = "/run/current-system/sw/bin/fish";
      default_layout = "default";
      session_serialization = false;
      pane_frames = false;
      session_name = "main-session";
      show_release_notes = false;
      show_startup_tips = false;
      theme = "dracula";
    };
  };
}
