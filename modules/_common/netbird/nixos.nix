{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhen.netbird;

  # NetBird 0.82 起 Config.ManagementURL 的类型是 *url.URL，
  # JSON 反序列化时要求对象形态（Scheme/Host/Path），不能直接写字符串，
  # 否则守护进程会报：cannot unmarshal string into Go struct field .ManagementURL of type url.URL。
  managementURLParts = urlParts cfg.managementUrl;

  urlParts =
    url:
    let
      m = builtins.match "(https?)://([^/]+)(/.*)?" url;
    in
    if m == null then
      throw "rhen.netbird.managementUrl 必须是 http(s)://host[/path] 形式，收到：${url}"
    else
      {
        Scheme = builtins.elemAt m 0;
        Host = builtins.elemAt m 1;
        Path = if builtins.elemAt m 2 == null then "" else builtins.elemAt m 2;
      };
in
{
  options.rhen.netbird = {
    enable = mkEnableOption "NetBird WireGuard 组网客户端";

    managementUrl = mkOption {
      type = types.str;
      default = "https://net.siiway.mfawa.top";
      description = ''
        NetBird 管理服务地址。写入客户端配置的 `ManagementURL`，
        让不带 `--management-url` 的 `netbird up` 也连到自建控制面。
      '';
    };
    ui.enable = mkOption {
      type = types.bool;
      default = false;
      description = "安装 netbird-ui 图形客户端，需要图形会话。";
    };

    port = mkOption {
      type = types.port;
      default = 51820;
      description = "WireGuard 监听 UDP 端口。";
    };

    interface = mkOption {
      type = types.str;
      default = "wt0";
      description = "WireGuard 网卡名，长度不得超过 15 个字符。";
    };

    disableDNS = mkOption {
      type = types.bool;
      default = true;
      description = ''
        保持系统 DNS 仍由本机 mihomo（127.0.0.1:53）接管。

        NetBird 默认会改写 /etc/resolv.conf 接管 DNS，与本机 DNS 代理冲突，
        因此这里默认让 NetBird 不接管 DNS；需要解析 NetBird 内网域名时再改为 false。
      '';
    };
  };

  config = mkIf cfg.enable {
    services.netbird = {
      enable = true;
      ui.enable = cfg.ui.enable;

      clients.default = {
        port = cfg.port;
        interface = cfg.interface;
        # hardened 会创建 netbird 用户/组，组员可直接访问 daemon socket，
        # 免 sudo 执行 netbird status / up / down。
        hardened = true;

        # 会以 /etc/netbird/config.d/50-nixos.json 的形式合并进
        # /var/lib/netbird/config.json，服务每次启动前生效。
        config = {
          ManagementURL = managementURLParts;
        }
        // optionalAttrs cfg.disableDNS {
          DisableDNS = true;
        };
      };
    };

    # hardened 客户端只允许 netbird 组成员访问 daemon socket，
    # 加入该组后主用户可以直接执行 netbird status / up / down。
    users.users.${config.rhen.user.name}.extraGroups = [ "netbird" ];
  };
}
