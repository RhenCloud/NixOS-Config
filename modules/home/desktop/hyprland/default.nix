{ pkgs
, inputs
, ...
}:

let
  cloudPyprland = inputs.cloud-pyprland.packages.${pkgs.stdenv.hostPlatform.system}.default;
  # pythonEnv = pkgs.python312.withPackages (ps: with ps; [
  #   cloudPyprland
  # ]);
in
{
  xdg.configFile = {
    "hypr" = {
      source = ./hypr;
      recursive = true; # 递归整个文件夹
    };
    # "pypr" = {
    #   source = ./pypr;
    #   recursive = true; # 递归整个文件夹
    # };
  };

  home.sessionVariables.NIXOS_OZONE_WL = "1";
  home.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
  home.sessionVariables.XDG_MENU_PREFIX = "plasma-";

  home.packages = with pkgs; [
    hyprcursor
    pyprland
    (pkgs.writeShellScriptBin "cloud-pyprland" ''
      # 把插件的 site-packages 加进 PYTHONPATH
      export PYTHONPATH="${cloudPyprland}/${pkgs.python3.sitePackages}:$PYTHONPATH"
      exec "${pkgs.pyprland}/bin/pypr" "$@"
    '')
    # pythonEnv
    # cloudPyprland
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    systemd.enable = true;
    extraConfig = ''
      source = ~/.config/hypr/hyprland.conf
    '';
    plugins = [
      pkgs.hyprlandPlugins.hypr-dynamic-cursors
    ];
  };
}
