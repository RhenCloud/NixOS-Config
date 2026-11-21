{
  config,
  lib,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhen.services.aria2;
  # 本机归档器通过 127.0.0.1 调 RPC，回环必须始终放行。
  rpcAllowSet = [ "127.0.0.0/8" ] ++ cfg.rpcAllowedSources;
in
{
  options.rhen.services.aria2 = {
    enable = mkEnableOption "aria2 下载守护进程（供 OpenList 离线下载使用）";

    rpcPort = mkOption {
      type = types.port;
      default = 6800;
      description = "JSON-RPC 监听端口；`rpcListenAll = false` 时仅绑定 127.0.0.1";
    };

    rpcListenAll = mkOption {
      type = types.bool;
      default = false;
      description = ''
        是否让 RPC 监听所有地址（rpc-listen-all）。
        公网暴露时务必同时设置 `rpcAllowedSources` 限制源地址，
        因为 aria2 RPC 允许写任意路径，仅靠 token 不够。
      '';
    };

    rpcAllowedSources = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "81.31.208.183" ];
      description = ''
        允许访问 RPC 端口的源地址（IP 或 CIDR）。非空时用 nftables
        丢弃其它来源的流量；为空表示不加任何限制。
        仅在 `rpcListenAll = true` 时有意义。
      '';
    };

    rpcSecretName = mkOption {
      type = types.str;
      default = "aria2-rpc-secret";
      description = "sops 中保存 RPC 密钥的键名";
    };

    mountPoints = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/Data2" ];
      description = "启动前必须已挂载的路径（下载目录所在磁盘）";
    };

    downloadDir = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/Data2/openlist-download";
      description = ''
        aria2 默认下载目录。必须与 OpenList 的临时目录位于同一文件系统，
        否则 OpenList 转移文件时的 rename 会跨设备失败。
        目录需要事先创建好，模块不会自动创建（避免在挂载点未就绪时
        在根文件系统上建出同名目录）。
      '';
    };

    maxConcurrentDownloads = mkOption {
      type = types.int;
      default = 5;
      description = ''
        同时下载的任务数上限（max-concurrent-downloads）。
        小盘主机的下载暂存区容量有限，应降到 1 以保证串行。
      '';
    };

    btMaxPeers = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 30;
      description = "单个 BT 任务的最大 peer 数；null 表示沿用 aria2 默认值。";
    };

    diskCacheMiB = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 16;
      description = "aria2 磁盘缓存大小（MiB）；null 表示不设置，改用 aria2 默认值。";
    };

    maxOverallUploadLimit = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 1024;
      description = ''
        全局上传限速（max-overall-upload-limit，单位 B/s）；null 表示不限速。
        seed-time 固定为 0，aria2 不做种；此项只用于压掉 BT 协议在下载
        过程中必须回传的少量数据。最小值受 aria2 限制为 1，不能填 0。
      '';
    };

    extraTrackers = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "udp://tracker.opentrackr.org:1337/announce" ];
      description = ''
        追加到每个 BT 任务的额外 tracker（bt-tracker）。
        用于种子里自带的 tracker 大面积不可达时补充 peer 来源；
        只应填入本机实测可用的地址。
      '';
    };

    excludeTrackers = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "*tr.bangumi.moe*" ];
      description = ''
        从每个 BT 任务中剔除的 tracker（bt-exclude-tracker），
        支持 aria2 的通配符语法。剔除不可达的 tracker 可以避免
        每次 announce 都白等一个超时周期。
      '';
    };

    dhtEntryPoint = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "dht.transmissionbt.com:6881";
      description = ''
        DHT bootstrap 节点（dht-entry-point），只接受单个 HOST:PORT；
        aria2 不接受逗号分隔列表，填多个会导致进程启动时参数解析失败。
        aria2 自带的默认节点在部分链路上不可达，会导致 DHT 路由表长期为空、
        peer 发现只能依赖 tracker，表现为刚加任务时长时间 0 连接。
      '';
    };

    forceSave = mkOption {
      type = types.bool;
      default = false;
      description = ''
        是否强制保存已完成的任务记录（force-save）。
        开启后已完成任务在服务重启后仍可通过 tellStopped 查到，
        适合由外部归档程序事后领取并清理的场景。
      '';
    };

    resumeOnRestart = mkOption {
      type = types.bool;
      default = false;
      description = ''
        重启后恢复未完成的下载。开启后写入 save-session / input-file
        （路径与 nixpkgs aria2 模块的状态目录一致）并每 60 秒落盘一次。
      '';
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.${cfg.rpcSecretName} =
      snowveil.sops.secret {
        source = "host";
        host = config.networking.hostName;
      }
      // {
        mode = "0400";
      };

    services.aria2 = {
      enable = true;
      rpcSecretFile = config.sops.secrets.${cfg.rpcSecretName}.path;

      # 只放开 OpenList 需要的部分；rpc-listen-all 保持关闭，
      # 因为 OpenList 容器以 hostNetwork 运行时 127.0.0.1 即可互通。
      settings = {
        continue = true;
        file-allocation = "none";
        max-concurrent-downloads = cfg.maxConcurrentDownloads;
        max-connection-per-server = 8;
        split = 16;
        min-split-size = "1M";
        seed-time = 0;
        follow-torrent = true;
        bt-save-metadata = true;
        rpc-listen-all = cfg.rpcListenAll;
        rpc-listen-port = cfg.rpcPort;
      }
      // optionalAttrs (cfg.downloadDir != null) {
        dir = cfg.downloadDir;
      }
      // optionalAttrs (cfg.btMaxPeers != null) {
        bt-max-peers = cfg.btMaxPeers;
      }
      // optionalAttrs (cfg.diskCacheMiB != null) {
        disk-cache = "${toString cfg.diskCacheMiB}M";
      }
      // optionalAttrs (cfg.maxOverallUploadLimit != null) {
        max-overall-upload-limit = cfg.maxOverallUploadLimit;
      }
      // optionalAttrs (cfg.extraTrackers != [ ]) {
        bt-tracker = concatStringsSep "," cfg.extraTrackers;
      }
      // optionalAttrs (cfg.excludeTrackers != [ ]) {
        bt-exclude-tracker = concatStringsSep "," cfg.excludeTrackers;
      }
      // optionalAttrs (cfg.dhtEntryPoint != null) {
        dht-entry-point = cfg.dhtEntryPoint;
      }
      // optionalAttrs cfg.forceSave {
        force-save = true;
      }
      // optionalAttrs cfg.resumeOnRestart {
        save-session = "/var/lib/aria2/session";
        input-file = "/var/lib/aria2/session";
        save-session-interval = 60;
      };
    };

    systemd.services.aria2 = {
      after = [
        "network-online.target"
        "sops-install-secrets.service"
      ];
      wants = [ "network-online.target" ];
      requires = [ "sops-install-secrets.service" ];
      unitConfig.RequiresMountsFor = cfg.mountPoints;

      serviceConfig = {
        # 下载落在 NTFS（ntfs-3g/FUSE）或其它 ACL 挂载点时，
        # aria2 用户对其中的临时目录没有写权限，因此以 root 运行。
        User = mkForce "root";
        Group = mkForce "root";
      };
    };

    # 公网暴露 RPC 时用源地址白名单兼作第一道防线：
    # 只丢掉目标为 RPC 端口的非白名单流量，其余入站不受影响，
    # 因此无需打开整体防火墙（本机可能还有别的服务在裸奔）。
    networking.nftables.enable = mkIf (cfg.rpcAllowedSources != [ ]) (mkDefault true);
    networking.nftables.tables = mkIf (cfg.rpcAllowedSources != [ ]) {
      aria2-rpc = {
        family = "inet";
        content = ''
          chain input {
            type filter hook input priority -5; policy accept;
            ip saddr != { ${concatStringsSep ", " rpcAllowSet} } tcp dport ${toString cfg.rpcPort} counter drop
            # IPv6 只放行回环（白名单只支持 v4，避免 [::] 监听绕过限制）。
            ip6 saddr != ::1 tcp dport ${toString cfg.rpcPort} counter drop
          }
        '';
      };
    };
  };
}
