{
  config,
  lib,
  pkgs,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhen.services.animeArchive;

  # aria2 的 RPC 端口与密钥由 server/aria2 模块声明，本模块只消费。
  aria2Enabled = config.rhen.services ? aria2 && config.rhen.services.aria2.enable;

  archiver = pkgs.writeShellApplication {
    name = "anime-archiver";
    runtimeInputs = [
      pkgs.python3
      pkgs.curl
      pkgs.coreutils
    ];
    text = ''exec python3 ${./archiver.py} "$@"'';
  };

  # 非密钥配置走 JSON；密钥只传路径，避免进 /nix/store。
  configFile = (pkgs.formats.json { }).generate "anime-archive.json" {
    downloadRoot = cfg.downloadRoot;
    stateDir = cfg.stateDir;
    settleSeconds = cfg.settleSeconds;
    retryMax = cfg.retryMax;
    lowWaterGiB = cfg.lowWaterGiB;
    criticalGiB = cfg.criticalGiB;
    monthlyDownloadBudgetGiB = cfg.monthlyDownloadBudgetGiB;
    maxParallelUploads = cfg.maxParallelUploads;
    uploadBackend = cfg.uploadBackend;
    verifyMode = cfg.verifyMode;
    dryRun = cfg.dryRun;
    purgeLeftovers = cfg.purgeLeftovers;
    orphanScan = {
      inherit (cfg.orphanScan) enable minAgeMinutes;
    };
    abUrl = cfg.abUrl;
    notifyCommand = cfg.notifyCommand;
    targets = map (target: {
      inherit (target) name mount quotaGiB;
    }) cfg.targets;
    naming = {
      inherit (cfg.naming)
        template
        seasonDir
        extraDir
        includeYear
        subtitleSuffix
        keepGroupTag
        abMetadata
        ;
    };
    index = {
      inherit (cfg.index)
        enable
        path
        unnamedPath
        flushEvery
        flushDailyHours
        ;
    };
    library = {
      inherit (cfg.libraryIndex) enable root path;
    };
    aria2 = {
      rpcUrl = cfg.aria2.rpcUrl;
      secretFile = config.sops.secrets.${cfg.aria2.secretSecret}.path;
    };
    openlist = {
      url = cfg.openlist.url;
      tokenFile = config.sops.secrets.${cfg.openlist.tokenSecret}.path;
    };
  };
in
{
  options.rhen.services.animeArchive = {
    enable = mkEnableOption "追番归档器（本地下载 → 云盘上传 → 立即清理）";

    downloadRoot = mkOption {
      type = types.str;
      default = "/var/lib/anime";
      description = ''
        下载与暂存根目录。模块会把该路径建为 Btrfs 子卷并施加 QGROUP 硬限额，
        使下载暂存不会耗尽根分区。
      '';
    };

    quotaGiB = mkOption {
      type = types.int;
      default = 8;
      description = ''
        归档区 QGROUP 限额（GiB）。应按剩余磁盘空间而非单集体积设定：
        峰值为「正在下载的一集 + 正在上传的一集」，通常 8 GiB 已足够。
      '';
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/anime-archive";
      description = "归档器状态目录，保存 state.json 与运行状态。";
    };

    aria2 = {
      rpcUrl = mkOption {
        type = types.str;
        default = "http://127.0.0.1:6800/jsonrpc";
        description = "aria2 JSON-RPC 地址（远端主机时指向 SSH 隧道本地端口）。";
      };

      secretSecret = mkOption {
        type = types.str;
        default = "aria2-rpc-secret";
        description = "sops 中保存 aria2 RPC 密钥的键名。";
      };
    };

    openlist = {
      url = mkOption {
        type = types.str;
        default = "http://127.0.0.1:5244";
        description = "OpenList API 地址，必须与下载器同机。";
      };

      tokenSecret = mkOption {
        type = types.str;
        default = "openlist-api-token";
        description = "sops 中保存 OpenList API token 的键名。";
      };
    };

    targets = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "目标标识，用于状态记录，例如 onedrive。";
            };

            mount = mkOption {
              type = types.str;
              example = "/onedrive/Anime";
              description = "OpenList 中的目标目录（挂载路径 + 归档子目录）。";
            };

            quotaGiB = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = ''
                该目标的总容量（GiB），仅用于容量水位推算与告警；
                null 表示不跟踪。
              '';
            };
          };
        }
      );
      default = [ ];
      description = ''
        归档目标列表。单目标时流量约为下载量的 2 倍；每增加一个目标，
        上传流量增加一份，必须同步下调 monthlyDownloadBudgetGiB。
      '';
    };

    naming = {
      template = mkOption {
        type = types.str;
        default = "{title} S{season:02}E{episode:02}{ext}";
        description = "输出文件名模板。";
      };

      seasonDir = mkOption {
        type = types.str;
        default = "Season {season:02}";
        description = "季目录名模板，位于 <mount>/<标题>/ 之下。";
      };

      extraDir = mkOption {
        type = types.str;
        default = "Extra";
        description = ''
          季目录下存放非视频文件（字幕、字体包、封面等）的子目录名。
          字幕文件仍然按集命名（含 SxxExx），但不再与正片同目录。
        '';
      };

      includeYear = mkOption {
        type = types.bool;
        default = false;
        description = "标题目录是否附加年份（<标题> (YYYY)）。";
      };

      subtitleSuffix = mkOption {
        type = types.bool;
        default = true;
        description = "字幕文件是否把语言标记（chs/cht/sc/tc）并列到主视频同名之后。";
      };

      keepGroupTag = mkOption {
        type = types.bool;
        default = false;
        description = "是否在文件名中保留字幕组方括号标记；溯源信息改由归档索引的「原始种子名」列保留。";
      };

      abMetadata = mkOption {
        type = types.bool;
        default = true;
        description = "是否优先使用 AutoBangumi 的季集元数据命名，失败时退回正则解析。";
      };
    };

    index = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "是否在云盘生成归档索引与命名失败清单。";
      };

      path = mkOption {
        type = types.str;
        default = "/onedrive/Anime/_archive-index.md";
        description = "归档索引的 OpenList 路径，整文件覆盖上传。";
      };

      unnamedPath = mkOption {
        type = types.str;
        default = "/onedrive/Anime/_unnamed.md";
        description = "命名失败清单的 OpenList 路径，与索引分开维护。";
      };

      flushEvery = mkOption {
        type = types.int;
        default = 10;
        description = "每归档多少集重算并上传一次索引。";
      };

      flushDailyHours = mkOption {
        type = types.int;
        default = 24;
        description = "无论归档数量，最长多少小时刷新一次索引。";
      };
    };

    libraryIndex = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "是否定期扫描云盘目录，生成番剧库总览 markdown（供 OpenList 直接阅读）。";
      };

      root = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/Private/OneDrive/Anime";
        description = "扫描的云端根目录；null 表示取第一个 targets 的 mount。";
      };

      path = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/Private/OneDrive/Anime/README.md";
        description = "总览文件的云端路径；null 表示放在扫描根目录下的 README.md。";
      };

      intervalHours = mkOption {
        type = types.int;
        default = 24;
        description = "两次扫描之间的间隔小时数。";
      };
    };

    purgeLeftovers = mkOption {
      type = types.bool;
      default = false;
      description = ''
        归档成功后删除种子目录里未被归档的剩余文件（字体包、封面、.aria2 控制文件、种子元数据）。
        开启后每个种子可回收约 100 MiB；关闭时这些文件会一直堆在下载区。
      '';
    };

    orphanScan = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          是否兜底扫描下载区里“已完成但已被 aria2 遗忘”的文件。
          aria2 重启后可能丢掉已完成任务的记录，归档器就再也领不到它们；
          开启后按目录把这类孤儿文件重新合成为种子记录并归档。
        '';
      };

      minAgeMinutes = mkOption {
        type = types.int;
        default = 60;
        description = "孤儿文件至少多久没被修改过才处理（避免误抓正在写入的文件）。";
      };
    };

    settleSeconds = mkOption {
      type = types.int;
      default = 180;
      description = "文件稳定窗口：连续两次采样一致才认为写入完成。";
    };

    retryMax = mkOption {
      type = types.int;
      default = 5;
      description = "单次上传失败的最大重试次数（指数退避）。";
    };

    lowWaterGiB = mkOption {
      type = types.numbers.nonnegative;
      default = 4;
      description = "低于该剩余空间值时不再领取新任务。";
    };

    criticalGiB = mkOption {
      type = types.numbers.nonnegative;
      default = 2.5;
      description = "低于该剩余空间值时暂停全部下载并告警。";
    };

    monthlyDownloadBudgetGiB = mkOption {
      type = types.int;
      default = 200;
      description = ''
        每月下载预算（GiB）。归档器按此记账，耗尽后暂停领取至次月。
        实际出口流量约为该值的两倍（下载 + 每个目标一份上传）。
      '';
    };

    maxParallelUploads = mkOption {
      type = types.int;
      default = 1;
      description = "同时进行的上传数；小内存主机保持 1。";
    };

    uploadBackend = mkOption {
      type = types.enum [
        "openlist"
        "rclone"
      ];
      default = "openlist";
      description = "上传通道实现。";
    };

    verifyMode = mkOption {
      type = types.enum [
        "size"
        "hash"
      ];
      default = "size";
      description = "上传后的校验方式；hash 需要额外下行一次，代价高。";
    };

    dryRun = mkOption {
      type = types.bool;
      default = true;
      description = "演练模式：只打印将要执行的重命名/上传/删除，不真正改动。上线首日必须为 true。";
    };

    abUrl = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "http://127.0.0.1:7892";
      description = "AutoBangumi WebUI 地址，用于查询季集元数据；null 表示只用正则解析。";
    };

    notifyCommand = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/run/current-system/sw/bin/notify-send" ];
      description = "hold 状态变化时调用的通知命令，原因作为最后一个参数附加。";
    };

    smallDiskMode = mkOption {
      type = types.bool;
      default = true;
      description = ''
        小盘主机模式：限制 systemd-journald 的日志占用（SystemMaxUse=200M）。
        该设置是主机全局的，仅在磁盘紧张的主机上启用。
      '';
    };
  };

  config = mkIf cfg.enable {
    # 小盘主机：限制日志占用，避免 30 GiB 级别的根分区被 journal 吃掉。
    services.journald.settings.Journal.SystemMaxUse = mkIf cfg.smallDiskMode "200M";

    assertions = [
      {
        assertion = aria2Enabled;
        message = "rhen.services.animeArchive 依赖 rhen.services.aria2 提供下载与 RPC 密钥。";
      }
      {
        # 空目标会让归档器把文件白白搬进暂存区，宁可开机前就报错。
        assertion = cfg.targets != [ ];
        message = "rhen.services.animeArchive.targets 不能为空，至少需要一个 OpenList 挂载点。";
      }
      {
        assertion = length cfg.targets <= 1 || cfg.monthlyDownloadBudgetGiB <= 130;
        message = "多个归档目标会让上行流量成倍增长，请把 monthlyDownloadBudgetGiB 降到 130 以内。";
      }
      {
        assertion = cfg.uploadBackend == "openlist";
        message = "uploadBackend = \"rclone\" 尚未实现；当前只有 OpenList 上传后端。";
      }
    ];

    sops.secrets.${cfg.openlist.tokenSecret} =
      snowveil.sops.secret {
        source = "host";
        host = config.networking.hostName;
      }
      // {
        owner = "root";
        mode = "0400";
      };

    systemd.services.anime-archiver = mkIf aria2Enabled {
      description = "追番归档器";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "sops-install-secrets.service"
        "aria2.service"
      ];
      requires = [ "btrfs-anime-setup.service" ];
      serviceConfig = {
        ExecStart = "${archiver}/bin/anime-archiver${optionalString cfg.dryRun " --dry-run"}";
        Environment = [ "ANIME_ARCHIVE_CONFIG=${configFile}" ];
        Restart = "always";
        RestartSec = 30;
        # 单进程常驻内存约 40 MiB；上限用于防止意外膨胀。
        MemoryHigh = "128M";
        MemoryMax = "160M";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        ReadWritePaths = [
          cfg.downloadRoot
          cfg.stateDir
        ];
      };
    };

    # 番剧库总览：扫描云端目录而不是本地状态，因此云盘里有什么就展示什么。
    systemd.services.anime-library-index = mkIf cfg.libraryIndex.enable {
      description = "番剧库总览生成";
      wants = [ "network-online.target" ];
      after = [
        "network-online.target"
        "sops-install-secrets.service"
        "openlist.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${archiver}/bin/anime-archiver --library";
        Environment = [ "ANIME_ARCHIVE_CONFIG=${configFile}" ];
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        ReadWritePaths = [ cfg.stateDir ];
      };
    };

    systemd.timers.anime-library-index = mkIf cfg.libraryIndex.enable {
      description = "定期刷新番剧库总览";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        Unit = "anime-library-index.service";
        OnBootSec = "10min";
        OnUnitActiveSec = "${toString cfg.libraryIndex.intervalHours}h";
        AccuracySec = "5min";
      };
    };

    # 归档区子卷与 QGROUP 限额。必须在 aria2 开始写之前完成，
    # 因此不用 tmpfiles（它在 sysinit 阶段会先建出普通目录，导致子卷创建失败）。
    systemd.services."btrfs-anime-setup" = {
      description = "创建归档区 Btrfs 子卷并设置 QGROUP 限额";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      before = [ "aria2.service" ];
      path = [
        pkgs.btrfs-progs
        pkgs.util-linux
        pkgs.coreutils
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        root="${cfg.downloadRoot}"

        if btrfs subvolume show "$root" >/dev/null 2>&1; then
          :
        elif [ -d "$root" ]; then
          # aria2 等模块的 tmpfiles 会在 sysinit 阶段先把目录建出来（含空的 downloads/）。
          # 只要里面没有真实文件，就清掉空目录后换成子卷，否则限额根本没地方挂。
          if [ -n "$(find "$root" -mindepth 1 ! -type d -print -quit 2>/dev/null)" ]; then
            echo "警告：$root 已存在且含文件，未创建子卷，跳过限额设置" >&2
          else
            find "$root" -mindepth 1 -depth -type d -delete 2>/dev/null || true
            rmdir "$root" 2>/dev/null || true
            btrfs subvolume create "$root"
          fi
        else
          install -d -m 0755 "$(dirname "$root")"
          btrfs subvolume create "$root"
        fi

        install -d -m 0755 "$root"
        install -d -m 0755 "$root/downloads"
        install -d -m 0755 "$root/incomplete"
        install -d -m 0700 "${cfg.stateDir}"

        if btrfs subvolume show "$root" >/dev/null 2>&1; then
          btrfs quota enable / 2>/dev/null || true
          btrfs qgroup limit ${toString cfg.quotaGiB}G "$root" \
            || echo "警告：$root 的 QGROUP 限额设置失败" >&2
        fi
      '';
    };
  };
}
