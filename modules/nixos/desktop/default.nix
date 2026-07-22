{ ... }:
{
  imports = [
    ./hyprland.nix
    ./thunar.nix
    ./games.nix
    ./steam.nix
    ./zen.nix
    # ./proxy.nix
  ];

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };
}
