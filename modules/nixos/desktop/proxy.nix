{ pkgs, ... }:
{
  programs.clash-verge = {
    enable = true;
    serviceMode = true;
    package = pkgs.clash-verge-rev;
    tunMode = true;
  };
  services.sing-box = {
    enable = true;
    package = pkgs.sing-box;
    settings = {
      log = {
        disabled = false;
        level = "error";
        timestamp = true;
      };
      dns = {
        rules = [ ];
      };
    };
  };
  environment.systemPackages = with pkgs; [
    sing-geoip
  ];
}
