{ ... }:
{
  networking = {
    useNetworkd = true;
    # 静态地址由下方形网络单元声明，关闭全局 DHCP，避免 nixpkgs 自动生成的
    # 99-ethernet-default-dhcp 单元触发已移除的 dhcpConfig 选项。
    useDHCP = false;
    # 暂时关闭防火墙以支持 FRP 动态端口转发（2222, 15244, 3001 等）、
    # Gost 隧道（23222-23224）、EasyTier Mesh VPN 及 RustDesk（21115-21119）；
    # SSH 运行于端口 22222 并已强制禁用密码认证（PasswordAuthentication = false）。
    firewall.enable = false;
  };

  systemd.network.wait-online.enable = false;

  systemd.network.networks."50-eth" = {
    matchConfig.MACAddress = "bc:24:11:50:dd:92";
    # 野草云已将机房链路迁移至 85.189.59.0/24 段，旧段 207.57.127.0/24 的
    # 回程 BGP 路由已撤销，仅剩部分前缀可达。继续仅使用旧 IP 会导致
    # 1.1.1.1、Cloudflare、飞书 IMAP 等目标不可达（同一目标换新 IP 即恢复）。
    # 过渡期双 IP 共存：新 IP 作为主地址承载出网流量，旧 IP 保留以备远端访问。
    address = [
      "85.189.59.172/24"
      "207.57.127.54/24"
    ];
    gateway = [ "85.189.59.254" ];
    dns = [
      "172.16.36.100"
      "172.16.36.101"
    ];
    # 静态地址已显式指定，无需再写 networkConfig.DHCP（该选项在新版 nixpkgs
    # 中会映射到已移除的 dhcpConfig，导致求值报错）。
    dhcpV4Config.UseDNS = false;
  };
}
