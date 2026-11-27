{
  pkgs,
  lib,
  config,
  inputs,
  snowveil,
  ...
}:
let
  hostName = "yc-hk-1";
in
{
  # 框架会自动导入 disk.nix（包含 disko 模块和配置）
  imports = [
    ({ config, ... }: {
      services.openssh.ports = [ config.rhen.server.ssh.port ];
    })
  ];

  networking.hostName = hostName;

  nixpkgs.hostPlatform = "x86_64-linux";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  rhen.server.install = {
    enable = true;
    disk = "/dev/sda";
  };

  rhen.server.ssh.port = 22222;

  zramSwap.enable = true;

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
      hash = "sha256-QSiwKqKvSxhksWBF4/MlBOpyXba5xOQ2sRwA0R7399E=";
    };
    environmentFile = config.sops.templates."caddy-env".path;
    # 注意：`trusted_proxies static { ranges ... }` 的块写法在 caddy 2.11 里会被静默忽略
    # （adapt 后只剩 {"source":"static"}），必须用平铺写法才会生成 ranges。
    # 136.85.52.129 是外部 CDN 的回源 IP；olist.rhen.cloud 的 A 记录指向 CDN，不指源站。
    globalConfig = ''
      servers {
        trusted_proxies_strict
        trusted_proxies static 47.243.223.74 136.85.52.129
      }
    '';
    virtualHosts."zen.rhen.cloud" = {
      extraConfig = ''
        tls {
          dns cloudflare {$CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:13339
      '';
    };
    virtualHosts."sleepy.rhen.cloud" = {
      extraConfig = ''
        tls {
          dns cloudflare {$CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:9010
      '';
    };
    # OpenList 文件列表（olist.rhen.cloud）。
    # 实例跑在本机（与 Google Drive 等需要外网的存储同机，能直连 Google）。
    # 证书由 Caddy 通过 Cloudflare DNS-01 签发，因此 A 记录可指向 CDN。
    virtualHosts."olist.rhen.cloud" = {
      extraConfig = ''
        tls {
          dns cloudflare {$CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:5244
      '';
    };
    virtualHosts."vw.rhen.cloud" = {
      extraConfig = ''
        tls {
          dns cloudflare {$CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:1880
      '';
    };
    # 走 Cloudflare CDN（橙云 + Full (strict)），使用 CF Origin 证书，不由 Caddy 申请
    virtualHosts."nb-recv.siinodes.dpdns.org" = {
      extraConfig = ''
        tls ${config.sops.secrets."caddy-nb-origin-cert".path} ${
          config.sops.secrets."caddy-nb-origin-key".path
        }
        reverse_proxy 127.0.0.1:9089
      '';
    };
    # NextBridge OneBot v11 WebSocket 对外入口（wss://nb.rhen.cloud/onebot/v11/qq_ely），
    # 仅反代 /onebot/ 路径，其余路径直接 404。
    # NextBridge 自身要求路径以 / 结尾，且只认 Authorization: Bearer 而不认 OneBot v11
    # 规范的 ?access_token=；这里做两点兼容，让标准写法也能连。
    virtualHosts."nb.rhen.cloud" = {
      extraConfig = ''
        tls {
          dns cloudflare {$CLOUDFLARE_API_TOKEN}
        }
        handle /onebot/* {
          @need_slash not path */
          rewrite @need_slash {http.request.uri.path}/
          @query_token query access_token=*
          request_header @query_token Authorization "Bearer {query.access_token}"
          reverse_proxy 127.0.0.1:9089
        }
        handle {
          respond "Not Found" 404
        }
      '';
    };
    # Aria2 WebUI（AriaNg）+ 同源 RPC 反代。
    # 只绑回环，由 Cloudflare Tunnel 对外，访问控制交给 Cloudflare Access。
    # 刻意不用 443：源站 443 一旦被人直连就能绕过 Access。
    # Tunnel 里的 Public hostname / Service 填：
    #   aria.rhen.cloud → http://127.0.0.1:8098
    virtualHosts.":8098" = {
      extraConfig = ''
        bind 127.0.0.1
        handle /jsonrpc {
          reverse_proxy 127.0.0.1:6800
        }
        handle {
          root * ${pkgs.ariang}/share/ariang
          file_server
        }
      '';
    };
    # AutoBangumi（hd-sg-1）用的 RPC 入口：DNS 走灰云直连源站（不套 CF，
    # 所以不能用 Access），只允许 SG 的固定出口 IP，其余来源直接断开。
    # 证书同样由 DNS-01 签发，因此 AB 的 httpx 能通过严格校验。
    virtualHosts."aria-rpc.rhen.cloud" = {
      extraConfig = ''
        tls {
          dns cloudflare {$CLOUDFLARE_API_TOKEN}
        }
        @sg remote_ip 81.31.208.183
        handle @sg {
          reverse_proxy 127.0.0.1:6800
        }
        handle {
          abort
        }
      '';
    };
  };

  sops.secrets."cloudflare-api-token" =
    snowveil.sops.secret {
      source = "host";
      host = "yc-hk-1";
    }
    // {
      owner = "root";
      mode = "0400";
    };

  sops.secrets."caddy-nb-origin-cert" =
    snowveil.sops.secret {
      source = "host";
      host = "yc-hk-1";
    }
    // {
      owner = config.services.caddy.user;
      mode = "0400";
      restartUnits = [ "caddy.service" ];
    };

  sops.secrets."caddy-nb-origin-key" =
    snowveil.sops.secret {
      source = "host";
      host = "yc-hk-1";
    }
    // {
      owner = config.services.caddy.user;
      mode = "0400";
      restartUnits = [ "caddy.service" ];
    };

  sops.templates."caddy-env" = {
    owner = "root";
    mode = "0400";
    content = "CLOUDFLARE_API_TOKEN=${config.sops.placeholder."cloudflare-api-token"}\n";
  };

  systemd.services.caddy = {
    after = [ "sops-install-secrets.service" ];
    requires = [ "sops-install-secrets.service" ];
  };

  rhen.services = {
    mihomo = {
      enable = false;
    };
    baota-probe.enable = false;
    nextbridge.enable = true;
    frp.enable = true;
    easytier.enable = true;
    vaultwarden.enable = true;
    sleepy.enable = true;
    mailer.enable = true;
    wyf9s-bot.enable = true;
    gost.enable = true;
    rustdesk.enable = true;
    yysong.enable = false; # migrated to 182.92.242.192 (Tencent Cloud) 2026-10-02
    openlist = {
      enable = true;
      # 本机已有镜像，避免每次启动联网校验 pull 卡住（镜像源不稳）
      pullPolicy = "missing";
    };
    oci-helper.enable = false; # 2026-11-21 停用：释放内存，且该模块 vhost 未配 DNS-01 导致证书续期一直失败
    beszel-agent = {
      enable = true;
      hubUrl = "https://monitor.siiway.top";
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFBJuAPyEOrgT8HMzEBHNEXXgGAN7JDgUJMBSQqLJZVq";
    };

    pds = {
      enable = false;
      role = "proxy";
    };

    # 追番归档链路：aria2 下载（同一台机上），anime-archiver 重命名后上传 OneDrive。
    # 30 GiB 根分区只剩约 14 GiB，因此并发 1、边下边传、上传校验通过立即删本地。
    aria2 = {
      enable = true;
      downloadDir = "/var/lib/anime/downloads";
      maxConcurrentDownloads = 1;
      btMaxPeers = 30;
      diskCacheMiB = 16;
      # 不做种（seed-time=0），这里再把 BT 协议层面必须回传的那点数据压到 1 KiB/s。
      maxOverallUploadLimit = 1024;
      # aria2 自带的 DHT bootstrap 节点在 HK 大多不可达，换成实测可用的（只能填一个）。
      dhtEntryPoint = "dht.transmissionbt.com:6881";
      # 种子自带的国内 tracker 在 HK 基本连不通，补一份实测可用的。
      extraTrackers = [
        "udp://tracker.opentrackr.org:1337/announce"
        "udp://open.stealth.si:80/announce"
        "udp://tracker.dler.org:6969/announce"
        "udp://tracker.internetwarriors.net:1337/announce"
        "udp://tracker.qu.ax:6969/announce"
        "udp://open.demonii.com:1337/announce"
        "https://nyaa.tracker.wf:7777/announce"
      ];
      # 这个域名已 CNAME 到 10.255.255.254（DNS 污染），announce 只会白等超时。
      excludeTrackers = [
        "*tr.bangumi.moe*"
        "*open.acgtracker.com*"
        "*t.acg.rip*"
        "*tk.7086.in*"
      ];
      forceSave = true;
      resumeOnRestart = true;
      # RPC 只监听 127.0.0.1；浏览器（AriaNg）与 AB 都经 Caddy 反代访问，
      # 见 services.caddy 里的 aria.rhen.cloud / aria-rpc.rhen.cloud。
    };
    animeArchive.enable = true;
    # 命名已在演练期验证正确，正式开启上传/校验/删本地。
    animeArchive.dryRun = false;
    # 归档成功后顺手清掉字体包/封面/种子元数据，避免每集残留 ~100 MiB。
    animeArchive.purgeLeftovers = true;
    # aria2 重启会丢掉已完成任务记录，靠扫描下载区兜底。
    animeArchive.orphanScan.enable = true;
    animeArchive.targets = [
      {
        name = "onedrive";
        # OpenList 里的真实存储路径（不是 /Public/Anime 那个 Alias，
        # 那边会把写入同时扇到 OneDrive 与 Aliyun，双写会破 200 GiB 预算）。
        mount = "/Private/OneDrive/Anime";
        quotaGiB = 1024;
      }
    ];
    animeArchive.index = {
      path = "/Private/OneDrive/Anime/_archive-index.md";
      unnamedPath = "/Private/OneDrive/Anime/_unnamed.md";
    };
    # 云盘番剧库总览：扫描云端目录，生成 OpenList 可直接渲染的 markdown。
    animeArchive.libraryIndex = {
      enable = true;
      root = "/Private/OneDrive/Anime";
      path = "/Private/OneDrive/Anime/README.md";
      intervalHours = 24;
    };
  };

  # 归档完成后尽快回收 Nix store，避免 30 GiB 根分区被旧 generation 吃掉。
  services.fast-nix-gc.deleteOlderThan = "3d";

  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };

  boot.initrd.kernelModules = [
    "virtio_blk"
    "virtio_pci"
    "virtio_scsi"
    "sd_mod"
  ];

  environment.systemPackages = with pkgs; [
    python3
    uv
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  virtualisation.podman = {
    dockerCompat = true;
    dockerSocket.enable = true;
  };

  rhen.services.postgresql = {
    databases = [
      {
        name = "nextbridge";
        user = "nextbridge";
        passwordSecret = "postgres-nextbridge-password";
      }
      {
        name = "yysong";
        user = "yysong";
        passwordSecret = "postgres-yysong-password";
      }
    ];
  };

  users.users = {
    rhencloud.openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+/7cpkWShU8aEDBq2StSJRSeVbFvj8BSEP85HEEtYZ i@rhen.cloud"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPuthZJ1ELm9QFDDUWBfzdfRZk5JE9iHOLWjU+QQTQbE cardno:FFFE_E046F201"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAG58osQ3CN5H/HQDalJkfuK3Av400OotDlcnC6MIJnG openpgp:0x10032875"
    ];
    root = {
      initialPassword = "nixos";
      openssh.authorizedKeys.keys = [
        # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+/7cpkWShU8aEDBq2StSJRSeVbFvj8BSEP85HEEtYZ i@rhen.cloud"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPuthZJ1ELm9QFDDUWBfzdfRZk5JE9iHOLWjU+QQTQbE cardno:FFFE_E046F201"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAG58osQ3CN5H/HQDalJkfuK3Av400OotDlcnC6MIJnG openpgp:0x10032875"
      ];
    };
  };
}
