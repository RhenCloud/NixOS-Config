{ pkgs
, inputs
, ...
}:

let
  cloudPyprland = inputs.cloud-pyprland.packages.${pkgs.system}.default;
in
{

  # imports = [inputs.Hyprspace.nixModule];

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

  home.packages = with pkgs; [
    swww
    waypaper
    waylyrics
    hyprcursor
    pyprland
    cloudPyprland
    # pavucontrol
    hyprpolkitagent
    wl-clipboard
    clipse
    kdePackages.dolphin
    grim
  ];

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  };

  services = {
    flameshot = {
      enable = true;
      package = pkgs.flameshot.override { enableWlrSupport = true; };
      settings = {
        General = {
          useGrimAdapter = true;
        };
      };
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    systemd.enable = true;
    plugins = [
      pkgs.hyprlandPlugins.hypr-dynamic-cursors
      inputs.Hyprspace.packages.${pkgs.stdenv.hostPlatform.system}.Hyprspace
      # pkgs.hyprlandPlugins.hyprspace
    ];
  };
}
