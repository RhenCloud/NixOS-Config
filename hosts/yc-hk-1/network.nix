{ ... }:
{
  networking = {
    useNetworkd = true;
    # 暂时关闭防火墙以支持 FRP 动态端口转发（2222, 15244, 3001 等）、
    # Gost 隧道（23222-23224）、EasyTier Mesh VPN 及 RustDesk（21115-21119）；
    # SSH 运行于端口 22222 并已强制禁用密码认证（PasswordAuthentication = false）。
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
