{ ... }:
{
  networking = {
    useNetworkd = true;
    firewall.enable = false;
  };

  systemd.network.wait-online.enable = false;

  systemd.network.networks."50-eth" = {
    matchConfig.MACAddress = "bc:24:11:50:dd:92";
    address = [ "207.57.127.54/24" ];
    gateway = [ "207.57.127.254" ];
    dns = [
      "172.16.36.100"
      "172.16.36.101"
    ];
    networkConfig.DHCP = "no";
  };
}
