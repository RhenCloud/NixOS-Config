{ pkgs, ... }:
{
  home.packages = with pkgs; [ mprisence ];

  xdg.configFile."mprisence/config.toml".text = ''
    [template]
    details = "{{{title}}}"
    state = "{{{artist_display}}}"
    large_text = "{{#if album}}{{{album}}}{{#if year}} ({{{year}}}){{/if}}{{/if}}"

    [time]
    show = true

    [activity_type]
    use_content_type = true
    default = "listening"

    [player.musicfox]
    ignore = false

    [player.default]
    status_display_type = "details"
  '';

  systemd.user.services.mprisence = {
    Unit = {
      Description = "Discord Rich Presence for MPRIS media players";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.mprisence}/bin/mprisence";
      Restart = "on-failure";
      RestartSec = "5";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
