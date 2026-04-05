{ pkgs, ... }:
{
  home.packages = with pkgs; [
    awww
    waypaper
    linux-wallpaperengine
    waylyrics
    hyprpolkitagent
    clipse
    kdePackages.dolphin
    kdePackages.dolphin-plugins
    kdePackages.kservice
    shared-mime-info
    xdg-utils

    slurp
    grim
    satty

    playerctl

    wl-clipboard
    cliphist
    copyq
    nwg-clipman

    krita
    kdePackages.gwenview

    # microsoft-edge
  ];

  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Hyprland Polkit Authentication Agent";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 1;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

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

  programs.satty = {
    enable = true;
    settings = {
      general = {
        output-filename = "~/Pictures/Screenshots/Screenshot-%Y-%m-%d_%H:%M:%S.png";
      };
    };
  };
}
