{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhen.services.dnscryptProxy;
in
{
  options.rhen.services.dnscryptProxy = {
    enable = mkEnableOption "dnscrypt-proxy 本地 DoH 解析器";

    listenPort = mkOption {
      type = types.port;
      default = 53;
      description = "监听端口。系统 resolv.conf 只支持 IP 不支持端口，因此必须是 53。";
    };

    listenAddress = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "监听地址。";
    };
  };

  config = mkIf cfg.enable {
    # dnscrypt-proxy 监听 53，需要特权端口绑定能力
    systemd.services.dnscrypt-proxy.serviceConfig = {
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      Restart = "always";
      RestartSec = 3;
    };

    services.dnscrypt-proxy = {
      enable = true;
      settings = {
        listen_addresses = [ "${cfg.listenAddress}:${toString cfg.listenPort}" ];

        # 只用 DoH，强制加密，杜绝明文 UDP 53 污染
        ipv4_servers = true;
        ipv6_servers = false;
        dnscrypt_servers = false;
        doh_servers = true;
        odoh_servers = false;
        require_dnssec = false;
        require_nolog = false;
        require_nofilter = false;

        # 内联服务器定义：不依赖 public-resolvers.md 列表文件，
        # 且全部使用 IP 形式（stamp 里直接编码 IP），避免「解析 DoH 服务器自身」被投毒。
        # stamp 格式：0x02(DoH) + props(8B 全零) + addr + hash(空) + host + path
        static = {
          "cloudflare-1" = {
            stamp = "sdns://AgAAAAAAAAAABzEuMS4xLjEAEmNsb3VkZmxhcmUtZG5zLmNvbQovZG5zLXF1ZXJ5";
          };
          "cloudflare-2" = {
            stamp = "sdns://AgAAAAAAAAAABzEuMC4wLjEAEmNsb3VkZmxhcmUtZG5zLmNvbQovZG5zLXF1ZXJ5";
          };
        };
        server_names = [
          "cloudflare-1"
          "cloudflare-2"
        ];

        force_tcp = false;
        http3 = false;
        timeout = 3000;
        keepalive = 30;

        # 缓存
        cache = true;
        cache_size = 4096;
        cache_min_ttl = 600;
        cache_max_ttl = 86400;

        # 日志与隐私
        log_level = 2;
        use_syslog = true;

        # 回落：DoH 全部不可用时用国内 DNS 兜底（国内域名不污染）
        fallback_resolvers = [
          "223.5.5.5:53"
          "223.6.6.6:53"
        ];
        # bootstrap 仅用于下载 resolver 列表；stamp 已内联 IP，用国内地址即可
        bootstrap_resolvers = [
          "223.5.5.5:53"
          "223.6.6.6:53"
        ];
        ignore_system_dns = true;
        netprobe_timeout = 10;
        netprobe_address = "223.5.5.5:53";
      };
    };

    # 与 dnscrypt-proxy 争 53 端口，不启用 resolved
    services.resolved.enable = lib.mkForce false;

    # 系统 DNS 指向本地 dnscrypt-proxy
    networking.nameservers = [ cfg.listenAddress ];
  };
}
