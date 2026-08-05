{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.hm-hyprland;

  cloudPyprland = inputs.cloud-pyprland.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.rhencloud.hm-hyprland.enable = mkEnableOption "Hyprland (HM)";

  config = mkIf cfg.enable {
    xdg.configFile = {
      "hypr" = {
        source = ./hypr;
        recursive = true;
      };
      "hypr/pyprland.toml".source =
        config.lib.file.mkOutOfStoreSymlink "/run/secrets/rendered/pyprland.toml";
    };

    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      XDG_MENU_PREFIX = "plasma-";
    };

    home.packages = with pkgs; [
      hyprcursor
      pyprland
      (pkgs.writeShellScriptBin "cloud-pyprland" ''
        export PYTHONPATH="${cloudPyprland}/${pkgs.python3.sitePackages}:$PYTHONPATH"
        exec "${pkgs.pyprland}/bin/pypr" "$@"
      '')
    ];

    wayland.windowManager.hyprland = {
      enable = true;
      package = pkgs.hyprland;
      systemd.enable = true;
      extraConfig = ''
        source = ~/.config/hypr/hyprland.conf
      '';
    };
  };
}
