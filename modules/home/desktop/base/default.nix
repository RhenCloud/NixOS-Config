{ pkgs, ... }:
{
  home.packages = with pkgs; [
    awww
    waypaper
    # linux-wallpaperengine
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
    shutter

    playerctl

    wl-clipboard
    cliphist
    copyq
    nwg-clipman

    krita
    kdePackages.gwenview

    hyfetch

    # thunar
    # thunar-volman
    # thunar-vcs-plugin
    # thunar-archive-plugin
    # thunar-media-tags-plugin
    # gvfs
    kdePackages.ark
    rar
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

  # xdg.mimeApps = {
  #   enable = true;
  #   defaultApplications = {
  #     "text/html" = [
  #       "zen.desktop"
  #       "zen-browser.desktop"
  #     ];
  #     "application/xhtml+xml" = [
  #       "zen.desktop"
  #       "zen-browser.desktop"
  #     ];
  #     "x-scheme-handler/http" = [
  #       "zen.desktop"
  #       "zen-browser.desktop"
  #     ];
  #     "x-scheme-handler/https" = [
  #       "zen.desktop"
  #       "zen-browser.desktop"
  #     ];
  #     "x-scheme-handler/about" = [
  #       "zen.desktop"
  #       "zen-browser.desktop"
  #     ];
  #     "x-scheme-handler/unknown" = [
  #       "zen.desktop"
  #       "zen-browser.desktop"
  #     ];

  #     "x-scheme-handler/terminal" = [ "kitty.desktop" ];
  #     "application/x-terminal-emulator" = [ "kitty.desktop" ];

  #     "inode/directory" = [ "thunar.desktop" ];
  #     "application/x-gnome-saved-search" = [ "thunar.desktop" ];
  #     "x-scheme-handler/file" = [ "thunar.desktop" ];
  #   };
  # };

  home.sessionVariables = {
    BROWSER = "zen";
    TERMINAL = "kitty";
    EDITOR = "code";
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
