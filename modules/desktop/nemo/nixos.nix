{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhen.nemo;
in
{
  options.rhen.nemo = {
    enable = mkEnableOption "Nemo file manager";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.nemo-with-extensions
      pkgs.ffmpegthumbnailer # 视频 + 音频缩略图
      # 预览体验增强：补齐各类格式的缩略图后端
      # 这些包都自带 share/thumbnailers/*.thumbnailer，进 profile 即生效
      pkgs.evince # PDF / PS / EPS / DJVU / CBZ/CBR 漫画 / TIFF
      pkgs.gnome-epub-thumbnailer # epub / mobi 电子书封面
      pkgs.glycin-thumbnailer # HEIF / AVIF / JXL / SVG 等图片
      pkgs.glycin-loaders
    ];
  };
}
