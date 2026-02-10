{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    dae
  ];
  services.dae = {
    enable = true;

  };
}

