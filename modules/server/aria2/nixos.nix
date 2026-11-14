{
  config,
  lib,
  snowveil,
  ...
}:
with lib;
let
  cfg = config.rhen.services.aria2;
in
{
  options.rhen.services.aria2 = {
    enable = mkEnableOption "aria2 下载守护进程（供 OpenList 离线下载使用）";

    rpcPort = mkOption {
      type = types.port;
      default = 6800;
      description = "JSON-RPC 监听端口，仅绑定 127.0.0.1";
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
        max-concurrent-downloads = 5;
        max-connection-per-server = 8;
        split = 16;
        min-split-size = "1M";
        seed-time = 0;
        follow-torrent = true;
        bt-save-metadata = true;
        rpc-listen-all = false;
        rpc-listen-port = cfg.rpcPort;
      }
      // optionalAttrs (cfg.downloadDir != null) {
        dir = cfg.downloadDir;
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
  };
}
