{ pkgs, ... }: {
  home.packages = with pkgs; [
    swww
    waypaper
    linux-wallpaperengine
    waylyrics
    hyprpolkitagent
    wl-clipboard
    clipse
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.kservice
    shared-mime-info
    xdg-utils
    grim

    krita
    kdePackages.gwenview
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
          showDesktopNotification = false;
          showStartupLaunchMessage = false;
        };
      };
    };
  };
}
