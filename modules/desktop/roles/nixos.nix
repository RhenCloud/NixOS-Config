{ lib, ... }:
{
  config = {
    my.isDesktop = true;

    rhencloud = {
      # core
      boot.enable = true;
      identity.enable = true;
      env.enable = true;
      fonts.enable = true;
      nvidia.enable = true;
      locale.enable = true;
      nix.enable = true;
      fcitx5.enable = true;
      packages.enable = true;
      services.enable = true;
      shells.enable = true;
      xdg.enable = true;

      # desktop
      desktopPackages.enable = true;
      gnome.enable = false;
      hyprland.enable = true;
      umbriel.enable = true;
      mangowm.enable = true;
      thunar.enable = true;
      nemo.enable = true;
      games.enable = true;
      steam.enable = true;
      zen.enable = true;
      sunshine.enable = true;
      avahi.enable = true;

      # service
      bluetooth.enable = true;
      docker.enable = true;
      podman.enable = true;
      displayManagers.enable = true;
      easytier.enable = true;
      selector4nix.enable = true;
      sound.enable = true;
      qemu.enable = true;
    };
  };
}
