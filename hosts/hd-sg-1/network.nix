{ ... }:
{
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.wait-online.enable = false;
  systemd.network.networks."50-ethernet" = {
    matchConfig.Name = "ens192";
    address = [ "81.31.208.183/25" ];
    gateway = [ "81.31.208.129" ];
    dns = [
      "4.2.2.4"
      "8.8.4.4"
    ];
  };
}
