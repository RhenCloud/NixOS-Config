{
  config,
  lib,
  pkgs,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhencloud.services.easytier;
in
{
  options.rhencloud.services.easytier = {
    enable = mkEnableOption "EasyTier 全局 VPN 网络";
  };

  config = mkIf cfg.enable {
    sops.secrets."easytier-network-secret" = snowveil.sops.secret { source = "common"; } // {
      owner = "easytier";
      group = "easytier";
      mode = "0400";
    };

    sops.templates."easytier-hk.toml" = {
      owner = "easytier";
      group = "easytier";
      mode = "0400";
      content = ''
        instance_name = "hk"
        hostname = "rhencloud-hksrv"
        ipv4 = "10.114.2.10/16"
        dhcp = false
        listeners = [
          "tcp://0.0.0.0:11010",
          "udp://0.0.0.0:11010",
        ]
        peer = [
          { uri = "tcp://bee-hk-1.dns.siiway.top:11010" },
          { uri = "udp://bee-hk-1.dns.siiway.top:11010" },
          { uri = "tcp://killjsj-jp.dns.siiway.top:11010" },
          { uri = "udp://killjsj-jp.dns.siiway.top:11010" },
          { uri = "tcp://zmto.dns.wyf9.top:11010" },
          { uri = "udp://zmto.dns.wyf9.top:11010" },
          { uri = "tcp://zouter-us.dns.wyf9.top:11010" },
          { uri = "udp://zouter-us.dns.wyf9.top:11010" },
          { uri = "tcp://23.95.247.152:11010" },
          { uri = "udp://23.95.247.152:11010" },
          { uri = "tcp://acjpsb.dns.wyf9.top:11010" },
          { uri = "udp://acjpsb.dns.wyf9.top:11010" },
          { uri = "tcp://bee-us-1.dns.siiway.top:11010" },
          { uri = "udp://bee-us-1.dns.siiway.top:11010" },
          { uri = "tcp://52.141.56.126:11010" },
          { uri = "udp://52.141.56.126:11010" },
          { uri = "tcp://hk-wap-1.rhen.cloud:11010" },
          { uri = "udp://hk-wap-1.rhen.cloud:11010" },
        ]
        ipv6 = "fd00:fdfd::2:10/32"
        exit_nodes = []
        manual_routes = [
          "10.114.0.0/16",
          "fd00:fdfd::/32",
        ]

        [network_identity]
        network_name = "siiway-server-network-global"
        network_secret = "${config.sops.placeholder."easytier-network-secret"}"

        [flags]
        enable_private_mode = true
        default_protocol = "tcp"
        dev_name = "swnet-global"
        enable_encryption = true
        enable_ipv6 = true
        mtu = 1380
        latency_first = false
        enable_exit_node = false
        no_tun = false
        use_smoltcp = true
        disable_p2p = false
        p2p_only = false
        relay_all_peer_rpc = true
        disable_tcp_hole_punching = false
        disable_udp_hole_punching = false
        multi_thread_count = 4
        relay_network_whitelist = "siiway-server-network-global"
      '';
    };

    sops.templates."easytier-cn.toml" = {
      owner = "easytier";
      group = "easytier";
      mode = "0400";
      content = ''
        instance_name = "cn"
        hostname = "rhencloud-hksrv-cn"
        ipv4 = "10.114.0.10/16"
        dhcp = false
        listeners = [
          "tcp://0.0.0.0:11011",
          "udp://0.0.0.0:11011",
        ]
        peer = [
          { uri = "tcp://xpve-dual.dns.wyf9.top:31210" },
          { uri = "udp://xpve-dual.dns.wyf9.top:31210" },
          { uri = "tcp://gc2.yuholt.cn:11010" },
          { uri = "udp://gc2.yuholt.cn:11010" },
        ]
        ipv6 = "fd00:fdfd:0::10/32"
        exit_nodes = []
        manual_routes = [
          "10.114.0.0/16",
          "10.114.0.5/32",
          "fd00:fdfd::/32",
        ]

        [network_identity]
        network_name = "siiway-server-network-cn"
        network_secret = "${config.sops.placeholder."easytier-network-secret"}"

        [flags]
        enable_private_mode = true
        default_protocol = "tcp"
        dev_name = "swnet-cn"
        enable_encryption = true
        enable_ipv6 = true
        mtu = 1300
        latency_first = false
        enable_exit_node = false
        no_tun = false
        use_smoltcp = true
        disable_p2p = false
        p2p_only = false
        relay_all_peer_rpc = true
        disable_tcp_hole_punching = false
        disable_udp_hole_punching = false
        multi_thread_count = 3
        relay_network_whitelist = "siiway-server-network-cn"
      '';
    };

    services.easytier = {
      enable = true;

      instances.hk = {
        configFile = config.sops.templates."easytier-hk.toml".path;
      };

      instances.cn = {
        configFile = config.sops.templates."easytier-cn.toml".path;
      };
    };

    users.users.easytier = {
      isSystemUser = true;
      group = "easytier";
      description = "EasyTier daemon user";
    };
    users.groups.easytier = { };

    systemd.services."easytier-hk" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
      serviceConfig = {
        User = "easytier";
        Group = "easytier";
        AmbientCapabilities = [ "CAP_NET_ADMIN" ];
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
      };
    };

    systemd.services."easytier-cn" = {
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
      serviceConfig = {
        User = "easytier";
        Group = "easytier";
        AmbientCapabilities = [ "CAP_NET_ADMIN" ];
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
      };
    };

    systemd.services."easytier-cn-route" = {
      description = "为 CN EasyTier 实例安装目标主机路由";
      after = [ "easytier-cn.service" ];
      requires = [ "easytier-cn.service" ];
      wantedBy = [ "easytier-cn.service" ];
      partOf = [ "easytier-cn.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "easytier-cn-route" ''
          for _ in $(seq 1 60); do
            if ${pkgs.iproute2}/bin/ip link show dev swnet-cn >/dev/null 2>&1; then
              break
            fi
            sleep 1
          done
          ${pkgs.iproute2}/bin/ip link show dev swnet-cn >/dev/null 2>&1
          ${pkgs.iproute2}/bin/ip route replace 10.114.0.5/32 dev swnet-cn src 10.114.0.10
          ${pkgs.iproute2}/bin/ip route replace 10.114.1.2/32 dev swnet-cn src 10.114.0.10
        '';
      };
    };
  };
}
