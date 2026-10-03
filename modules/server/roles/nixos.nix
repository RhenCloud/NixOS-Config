{ lib, ... }:
{
  config = {
    rhen = {
      identity.enable = true;
      locale.enable = true;
      nix.enable = true;
      packages.enable = true;
      shells.enable = true;

      cloudflared.enable = true;
      services.postgresql.enable = true;
    };
  };
}
