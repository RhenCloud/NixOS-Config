{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.router;
in
{
  options.rhencloud.router.enable = mkEnableOption "soft router (bridge, hostapd, dhcpd, NAT)";

  config = mkIf cfg.enable {
    networking.useNetworkd = true;

    systemd.network = {
      netdevs."10-br0" = {
        netdevConfig.Name = "br0";
        netdevConfig.Kind = "bridge";
      };

      networks = {
        "10-br0" = {
          matchConfig.Name = "br0";
          networkConfig = {
            Address = "10.0.0.1/24";
            DHCPServer = true;
            IPMasquerade = "both";
            ConfigureWithoutCarrier = true;
          };
          dhcpServerConfig = {
            PoolOffset = 100;
            PoolSize = 151;
            DNS = [
              "10.0.0.1"
              "8.8.8.8"
            ];
            EmitDNS = true;
            EmitNTP = true;
            EmitRouter = true;
          };
        };

        "20-internal" = {
          matchConfig.Name = "intern*";
          linkConfig.Multicast = true;
          networkConfig.Bridge = "br0";
        };

        "25-wlan-internal" = {
          matchConfig.Name = "intern1";
          networkConfig = {
            Address = "10.0.1.1/24";
            IPMasquerade = "both";
          };
          dhcpServerConfig = {
            DNS = "10.0.1.1";
            EmitDNS = true;
            EmitNTP = true;
            EmitRouter = true;
          };
        };

        "30-external" = {
          matchConfig.Name = "extern0";
          networkConfig = {
            DHCP = "yes";
            IPv6AcceptRA = true;
            IPv6PrivacyExtensions = true;
          };
        };
      };
    };

    services.resolved = {
      enable = true;
      settings.Resolve.DNS = [
        "119.29.29.29"
        "223.5.5.5"
      ];
      settings.Resolve.FallbackDNS = [
        "1.1.1.1"
        "8.8.8.8"
      ];
    };

    services.hostapd = {
      enable = true;
      radios = {
        wlp1s0 = {
          band = "2g";
          channel = 6;
          countryCode = "CN";
          wifi4.enable = true;
          networks = {
            wlp1s0 = {
              ssid = "LinuxAP";
              authentication = {
                mode = "wpa2-sha1";
                pairwiseCiphers = [ "CCMP" ];
                wpaPasswordFile = pkgs.writeText "hostapd-password" "ljr811226";
              };
              settings."auth_algs" = 1;
            };
          };
        };
      };
    };

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.core.somaxconn" = 16384;
      "net.core.netdev_max_backlog" = 4096;
      "net.ipv4.tcp_rmem" = "4096 131072 67108864";
      "net.ipv4.tcp_wmem" = "4096 65536 67108864";
      "net.ipv4.tcp_keepalive_time" = 120;
      "net.ipv4.tcp_fin_timeout" = 30;
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.netfilter.nf_conntrack_max" = 524288;
      "net.netfilter.nf_conntrack_udp_timeout" = 180;
      "net.netfilter.nf_conntrack_udp_timeout_stream" = 180;
      "net.netfilter.nf_conntrack_tcp_timeout_established" = 432000;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.tcp_syncookies" = 1;
    };

    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune = {
        enable = true;
        flags = [
          "--all"
          "--filter until=72h"
        ];
      };
      daemon.settings = {
        registry-mirrors = [
          "https://docker.1ms.run"
          "https://docker.cattt.net"
        ];
        proxies = {
          "http-proxy" = "http://127.0.0.1:7890";
          "https-proxy" = "http://127.0.0.1:7890";
          "no-proxy" = "localhost,127.0.0.1";
        };
      };
    };

    systemd.services =
      let
        composeDirs = [
          "Mailer"
          "gitea"
          "napcat"
          "postgreSQL"
          "lucky"
          "openlist"
          "snappymail"
          "wakapi"
          "bili_tool_web"
          "mimo-api"
          "reader"
          "bangumi-rs"
          "vw"
          "tuwunel"
        ];
        composeUp = dir: ''
          cd /Data1/${dir}
          ${pkgs.docker-compose}/bin/docker-compose up -d
          ${pkgs.docker-compose}/bin/docker-compose start 2>/dev/null || true
        '';
      in
      builtins.listToAttrs (
        map (dir: {
          name = "docker-compose-${dir}";
          value = {
            description = "Docker Compose ${dir}";
            after = [
              "docker.service"
              "Data1.mount"
            ];
            requires = [
              "docker.service"
              "Data1.mount"
            ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = pkgs.writeShellScript "compose-up-${dir}" (composeUp dir);
              ExecStop = pkgs.writeShellScript "compose-down-${dir}" ''
                cd /Data1/${dir}
                ${pkgs.docker-compose}/bin/docker-compose down
              '';
            };
          };
        }) composeDirs
      )
      // {
        frpc = {
          description = "frp client";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.frp}/bin/frpc -c /Data1/frp/frpc.toml";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      };

    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
    };
    services.nginx = {
      enable = true;
      virtualHosts."localhost" = {
        listen = [
          {
            addr = "0.0.0.0";
            port = 80;
          }
        ];
        locations."/" = {
          root = "/usr/share/nginx/html";
          index = "index.html index.htm";
        };
      };
    };

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
      };
    };

    environment.pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];

    boot.kernelModules = [
      "kvm-intel"
      "nf_conntrack_netlink"
      "xt_nat"
      "xt_MASQUERADE"
    ];
  };
}
