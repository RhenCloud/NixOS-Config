{
  config,
  lib,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhen.services.wifiAp;

  # NetworkManager 用 shared 模式时由 dnsmasq 下发地址，但本机 NM 的服务 PATH 中
  # 不含 iptables/nft，无法写入 MASQUERADE 规则，表现为「能连上但上不了网」。
  # 因此 AP 的地址分配交给 NM，转发与 NAT 交给 NixOS 原生 networking.nat。
  profileId = "rhen-wifi-ap";
in
{
  options.rhen.services.wifiAp = {
    enable = mkEnableOption "WiFi 接入点（其他设备连入后可上网）";

    interface = mkOption {
      type = types.str;
      default = "wlp1s0";
      description = "用作接入点的无线网卡名";
    };

    ssid = mkOption {
      type = types.str;
      default = "Rhen-HomeServer";
      description = "热点名称";
    };

    passwordSecret = mkOption {
      type = types.str;
      default = "wifi-ap-password";
      description = "sops 中保存 WiFi 密码的密钥名（默认取主机密钥文件）";
    };

    upstreamInterface = mkOption {
      type = types.str;
      default = "enp3s0";
      description = "提供外网出口的上行网卡，NAT 将把 AP 流量伪装到该接口";
    };

    channel = mkOption {
      type = types.ints.between 1 13;
      default = 6;
      description = "2.4GHz 信道";
    };

    countryCode = mkOption {
      type = types.str;
      default = "CN";
      description = "监管域国家代码";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.interface != cfg.upstreamInterface;
        message = "wifiAp.interface 与 upstreamInterface 必须是不同的网卡";
      }
      {
        # 热点依赖 NetworkManager 的共享模式做地址分配。
        assertion = config.networking.networkmanager.enable;
        message = "rhen.services.wifiAp 需要 networking.networkmanager.enable = true";
      }
    ];

    sops.secrets.${cfg.passwordSecret} =
      snowveil.sops.secret {
        source = "host";
        host = "nixos-homeserver";
      }
      // {
        owner = "root";
        mode = "0400";
      };

    # psk 通过 environmentFiles + envsubst 注入，避免明文进入 Nix store。
    # environmentFiles 必须是 KEY=VALUE 格式，sops 密钥原文件只有裸密码，
    # 因此先用 sops.templates 渲染成规范的环境文件。
    sops.templates."wifi-ap.env".content = ''
      WIFI_AP_PASSWORD=${config.sops.placeholder.${cfg.passwordSecret}}
    '';

    networking.networkmanager.ensureProfiles = {
      environmentFiles = [ config.sops.templates."wifi-ap.env".path ];
      profiles.${profileId} = {
        connection = {
          id = "RhenCloud-AP";
          type = "wifi";
          autoconnect = true;
          autoconnect-priority = 10;
          interface-name = cfg.interface;
        };
        wifi = {
          mode = "ap";
          ssid = cfg.ssid;
          band = "bg";
          channel = cfg.channel;
        };
        wifi-security = {
          key-mgmt = "wpa-psk";
          proto = "rsn";
          pairwise = "ccmp";
          group = "ccmp";
          pmf = 1; # 1 = disable (可选/禁用保护帧，避免兼容性问题)
          psk = "$WIFI_AP_PASSWORD";
        };
        ipv4.method = "shared";
        ipv6.method = "ignore";
      };
    };

    # AP 网段地址由 NM shared 模式分配（默认 10.42.0.1/24），
    # 这里按同一网段声明 NAT，确保 MASQUERADE 一定存在。
    networking.nat = {
      enable = true;
      externalInterface = cfg.upstreamInterface;
      internalInterfaces = [ cfg.interface ];
    };

    # dhcpcd 与 NetworkManager 会同时争抢 wlp1s0（dhcpcd 不断改 MAC 并下发地址），
    # 导致 AP 激活后立刻掉线。这里把无线网卡从 dhcpcd 中排除，交给 NM 独占。
    networking.dhcpcd.denyInterfaces = [ cfg.interface ];

    # 允许无线客户端访问本机 DNS/DHCP。
    networking.firewall.interfaces.${cfg.interface} = {
      allowedUDPPorts = [
        53
        67
      ];
      allowedTCPPorts = [ 53 ];
    };

    # 无线网卡所在监管域，保证可用信道与功率合规。
    boot.kernelParams = [ "cfg80211.ieee80211_regdom=${cfg.countryCode}" ];
  };
}
