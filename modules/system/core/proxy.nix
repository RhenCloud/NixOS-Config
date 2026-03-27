{ pkgs, ... }:
{
  # environment.systemPackages = with pkgs; [
  # dae
  # v2rayn
  # ];
  # services.dae = {
  #   enable = true;
  #   configFile = ./config.dae;
  # };
  programs.clash-verge = {
    enable = false;
    tunMode = true;
    # package = pkgs.clash-nyanpasu;
    # autoStart = true;
  };
  # services.v2raya = {
  #   enable = true;
  # };

  # services.v2ray = {
  #   enable = true;
  #   package = pkgs.xray;
  #   config = {
  #     inbounds = [
  #       {
  #         port = 1080;
  #         protocol = "socks";
  #         tag = "socks";
  #       }
  #     ];
  #   };
  # };

}

