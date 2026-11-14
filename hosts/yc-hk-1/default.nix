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
    oci-helper.enable = true;
    beszel-agent = {
      enable = true;
      hubUrl = "https://monitor.siiway.top";
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFBJuAPyEOrgT8HMzEBHNEXXgGAN7JDgUJMBSQqLJZVq";
    };

    pds = {
      enable = false;
      role = "proxy";
    };
  };

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
    ];
    root = {
      initialPassword = "nixos";
      openssh.authorizedKeys.keys = [
        # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+/7cpkWShU8aEDBq2StSJRSeVbFvj8BSEP85HEEtYZ i@rhen.cloud"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPuthZJ1ELm9QFDDUWBfzdfRZk5JE9iHOLWjU+QQTQbE cardno:FFFE_E046F201"
      ];
    };
  };
}
