{ config, lib, ... }:
with lib;
let cfg = config.rhencloud.mangowm;
in {
  disabledModules = [ "programs/wayland/mango.nix" ];

  options.rhencloud.mangowm.enable = mkEnableOption "Mango WM";

  config = mkIf cfg.enable {
    programs.mango.enable = true;

    xdg.portal.config.mango = lib.mkForce {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
      "org.freedesktop.impl.portal.Inhibit" = [ "gtk" ];
      "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
    };
  };
}
