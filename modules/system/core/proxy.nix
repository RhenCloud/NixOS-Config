{ pkgs, ... }:
{
  # environment.systemPackages = with pkgs; [
  #   dae
  # ];
  # services.dae = {
  #   enable = true;
  #   configFile = ./config.dae;
  # };
  programs.clash-verge = {
    enable = true;
    tunMode = true;
    # package = pkgs.clash-nyanpasu;
    # autoStart = true;
  };
}

