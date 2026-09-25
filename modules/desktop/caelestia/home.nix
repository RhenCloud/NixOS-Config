{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.caelestia;
in
{
  options.rhencloud.caelestia.enable = mkEnableOption "Caelestia shell（手动启动，与 noctalia v5 共存）";

  config = mkIf cfg.enable {
    programs.caelestia = {
      enable = true;

      # 与 noctalia v5 共存：不挂 systemd 自启，需要时手动运行
      #   caelestia shell -d
      systemd.enable = false;

      cli.enable = true;

      settings = {
        general.apps = {
          terminal = [ "kitty" ];
          audio = [ "pavucontrol" ];
          playback = [ "mpv" ];
          explorer = [ "thunar" ];
        };
        paths.wallpaperDir = "~/Pictures/Wallpapers";
      };
    };
  };
}
