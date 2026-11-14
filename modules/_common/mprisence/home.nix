{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhen.mprisence;

  # 上游 nixpkgs 的 rust default-crate-overrides 对 aws-lc-sys >= 0.42.0 强制
  # AWS_LC_SYS_USE_SYSTEM=1 并注入 aws-lc，但 mprisence 的 buildInputs
  # 只声明了 dbus 与 openssl，导致找不到系统 AWS-LC 而构建失败。
  mprisence = pkgs.mprisence.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.aws-lc ];
  });
in
{
  options.rhen.mprisence.enable = mkEnableOption "MPRIS Discord Rich Presence";
  config = mkIf cfg.enable {
    home.packages = [ mprisence ];

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
        ExecStart = "${mprisence}/bin/mprisence";
        Restart = "on-failure";
        RestartSec = "5";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
