{
  pkgs,
  inputs,
  lib,
  ...
}:

let
  cloudPyprland = inputs.cloud-pyprland.packages.${pkgs.stdenv.hostPlatform.system}.default;

  sleepyToken = lib.strings.trim (builtins.readFile "${inputs.self}/secrets/sleepy-token");
in
{
  xdg.configFile = {
    "hypr" = {
      source = ./hypr;
      recursive = true;
    };
    "hypr/pyprland.toml".text = ''
      [pyprland]
      plugins = [
          "toggle_special",
          "fetch_client_menu",
          "expose",
          "cloud_pyprland.fcitx5_switcher",
          "cloud_pyprland.hdrop",
      ]

      [cloud_pyprland.sleepy]
      server_url = "https://sleepy.rhen.cloud"
      device_name = "Arch Linux"
      device_id = "archlinux"
      token = "${sleepyToken}"

      [cloud_pyprland.fcitx5_switcher]
      active_classes = ["wechat", "QQ", "zoom"]
      inactive_classes = [
          "code",
          "kitty",
          "musicfox",
          "google-chrome",
          "clipse",
          "org.wezfurlong.wezterm",
          "firefox",
      ]
      active_titles = ["微信"]
      inactive_titles = ["Minecraft .*"]

      [cloud_pyprland.hdrop.wechat]
      class = "wechat"
      floating = true
      center = true
      height = 700
      width = 1000
      launch_on_missing = false

      [cloud_pyprland.hdrop.musicfox]
      class = "musicfox"
      command = "kitty --class musicfox musicfox"
      floating = true
      center = true
      height = 700
      width = 1200
      launch_on_missing = true
    '';
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
}
