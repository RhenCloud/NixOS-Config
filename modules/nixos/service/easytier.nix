{ ... }:
{
  systemd.tmpfiles.rules = [ "d /etc/easytier 0700 root root -" ];

  services.easytier = {
    enable = true;

    instances.default = {
      environmentFiles = [ "/etc/easytier/default.env" ];

      settings = {
        instance_name = "default";
        hostname = "rhencloud";
        ipv4 = "10.114.0.5/16";
        dhcp = false;
        listeners = [
          "tcp://0.0.0.0:11010"
          "udp://0.0.0.0:11010"
        ];
        network_name = "siiway-server-network-cn";
        peers = [
          "tcp://xpve-dual.dns.wyf9.top:31210"
          "udp://xpve-dual.dns.wyf9.top:31210"
          "tcp://gc2.yuholt.cn:11010"
          "udp://gc2.yuholt.cn:11010"
        ];
      };

      extraSettings = {
        ipv6 = "fd00:fdfd:0::5/32";
        exit_nodes = [ ];
        manual_routes = [
          "10.114.0.0/16"
          "fd00:fdfd::/32"
        ];

        flags = {
          enable_private_mode = true;
          default_protocol = "udp";
          dev_name = "swnet-cn";
          enable_encryption = true;
          enable_ipv6 = true;
          mtu = 1300;
          latency_first = false;
          enable_exit_node = false;
          no_tun = false;
          use_smoltcp = false;
          disable_p2p = false;
          p2p_only = false;
          relay_all_peer_rpc = true;
          disable_tcp_hole_punching = false;
          disable_udp_hole_punching = false;
          multi_thread_count = 3;
          relay_network_whitelist = "siiway-server-network-cn";
        };
      };
    };
  };
}
