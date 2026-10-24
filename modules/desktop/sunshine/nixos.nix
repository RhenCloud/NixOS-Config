{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.rhen.sunshine;

  # 打包 2560x1600@60Hz 虚拟显示器 EDID 固件
  virtualEdidPkg = pkgs.runCommand "virtual-display-edid" { } ''
    mkdir -p $out/lib/firmware/edid
    cp ${./edid/virtual-display.bin} $out/lib/firmware/edid/virtual-display.bin
  '';
in
{
  options.rhen.sunshine = {
    enable = lib.mkEnableOption "Sunshine game streaming";
    virtualDisplay = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "启用基于 NVIDIA DRM 端口（DP-1）的虚拟副屏";
      };
      connector = lib.mkOption {
        type = lib.types.str;
        default = "DP-1";
        description = "虚拟副屏绑定的 DRM 接口名称";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # 开放 Moonlight/Sunshine 流式传输防火墙端口
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;

      # Sunshine 核心设置：默认抓取虚拟显示器，保持主机本地音频不静音
      settings = {
        output_name = lib.mkIf cfg.virtualDisplay.enable cfg.virtualDisplay.connector;
        encoder = "nvenc"; # GTX 1070 使用硬件编码，避免回退到 CPU 软件编码
        audio_sink = ""; # 保持系统默认音频，不重定向静音
      };

      # 提供应用列表供 Moonlight 快速连接
      applications.apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
          exclude-global-prep-cmd = "false";
          auto-detach = "true";
        }
      ];
    };

    # 虚拟副屏固件与内核参数注入
    hardware.display.edid = lib.mkIf cfg.virtualDisplay.enable {
      enable = true;
      packages = [ virtualEdidPkg ];
    };

    # 强制内核 DRM 激活未插入的接口并加载自定义 EDID
    boot.kernelParams = lib.mkIf cfg.virtualDisplay.enable [
      "drm.edid_firmware=${cfg.virtualDisplay.connector}:edid/virtual-display.bin"
      "video=${cfg.virtualDisplay.connector}:e"
    ];
  };
}
