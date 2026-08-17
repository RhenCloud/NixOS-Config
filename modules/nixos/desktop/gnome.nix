{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.gnome;
  extensions = with pkgs.gnomeExtensions; [
    appindicator
    blur-my-shell
    caffeine
    dash-to-dock
    impatience
    just-perfection
    no-overview
    user-themes
  ];
  enabledExtensions = [
    "appindicatorsupport@rgcjonas.gmail.com"
    "blur-my-shell@aunetx"
    "caffeine@patapon.info"
    "dash-to-dock@micxgx.gmail.com"
    "impatience@gfxmonk.net"
    "just-perfection-desktop@just-perfection"
    "no-overview@fthx"
    "user-theme@gnome-shell-extensions.gcampax.github.com"
  ];
in
{
  options.rhencloud.gnome.enable = mkEnableOption "GNOME 桌面环境";

  config = mkIf cfg.enable {
    services.desktopManager.gnome.enable = true;
    services.gnome.gnome-initial-setup.enable = false;

    environment.systemPackages = extensions;

    services.desktopManager.gnome.extraGSettingsOverrides = ''
      [org/gnome/shell]
      enabled-extensions=[${concatMapStringsSep ", " (x: "'${x}'") enabledExtensions}]

      [org/gnome/desktop/interface]
      color-scheme='prefer-dark'
      clock-show-date=true
      clock-show-weekday=true
    '';
  };
}
