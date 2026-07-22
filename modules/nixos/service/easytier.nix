{ ... }:
let
  etUser = "easytier";
in
{
  users.users.${etUser} = {
    isSystemUser = true;
    uid = 991;
    group = etUser;
    description = "EasyTier daemon user";
  };
  users.groups.${etUser} = { };

  systemd.tmpfiles.rules = [ "d /etc/easytier 0750 ${etUser} ${etUser} -" ];

  systemd.services."easytier-default" = {
    serviceConfig = {
      User = etUser;
      Group = etUser;
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
    };
  };

  systemd.services."easytier-rhencloud-network" = {
    serviceConfig = {
      User = etUser;
      Group = etUser;
      AmbientCapabilities = [ "CAP_NET_ADMIN" ];
      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
    };
  };

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
          disable_tcp_hole_pumping = false;
          disable_udp_hole_punching = false;
          multi_thread_count = 3;
          relay_network_whitelist = "siiway-server-network-cn";
        };
      };
    };

    instances.rhencloud-network = {
      settings = {
        instance_name = "rhencloud-network";
        hostname = "rhencloud";
        ipv4 = "10.115.0.1/24";
        dhcp = false;
        listeners = [
          "tcp://0.0.0.0:11011"
          "udp://0.0.0.0:11011"
        ];
        network_name = "rhencloud-network";
        peers = [
          "tcp://xpve-dual.dns.wyf9.top:31210"
          "udp://xpve-dual.dns.wyf9.top:31210"
          "tcp://gc2.yuholt.cn:11010"
          "udp://gc2.yuholt.cn:11010"
        ];
      };

      extraSettings = {
        ipv6 = "fd00:fdfd:115::1/64";
        exit_nodes = [ ];
        manual_routes = [
          "10.115.0.0/24"
          "fd00:fdfd:115::/64"
        ];

        flags = {
          enable_private_mode = true;
          default_protocol = "udp";
          dev_name = "rhenet";
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
          disable_tcp_hole_pumping = false;
          disable_udp_hole_punching = false;
          multi_thread_count = 3;
          relay_network_whitelist = "rhencloud-network";
        };
      };
    };
  };
}
