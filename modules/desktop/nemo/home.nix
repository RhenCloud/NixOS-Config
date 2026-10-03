{
  config,
  lib,
  ...
}:
with lib;
# Nemo 预览体验（键名对照 nemo 6.6.4 的 org.nemo.gschema.xml）：
# 旧配置里的 thumbnail-view / use-iec-units / enable-single-click /
# preferences-open-modal / show-sidebar / side-pane-width 都是已废弃/不存在的键，
# dconf 写入后实际不生效，这里换成有效键。
# 手动调过的键（executable-text-activation、show-full-path-titles 等）不在此声明，保留现状。
{
  dconf.settings = {
    "org/nemo/preferences" = {
      default-folder-viewer = "icon-view";
      show-hidden-files = false;
      show-image-thumbnails = "local-only"; # 网络位置不抽缩略图，本地全开
      # schema 类型是 uint64（t），必须用 mkUint64，普通 Nix 整数会按 int32 写入
      thumbnail-limit = lib.hm.gvariant.mkUint64 68719476736; # 64 GiB 以下都生成缩略图
      size-prefixes = "base-2-full"; # 用 KiB/MiB（原 use-iec-units=true）
      click-policy = "double"; # 原 enable-single-click=false
      date-format = "iso";
      sort-directories-first = true;

      # 悬停提示：文件类型 / 修改时间 / 完整路径，不打开面板也能快速预览信息
      tooltips-in-icon-view = true;
      tooltips-in-list-view = true;
      tooltips-show-file-type = true;
      tooltips-show-mod-date = true;
      tooltips-show-path = true;
    };

    "org/nemo/window-state" = {
      start-with-sidebar = true;
      sidebar-width = 200; # 原 side-pane-width 键不存在
    };

    "org/nemo/icon-view" = {
      default-zoom-level = "standard";
      thumbnail-size = 128; # 图标视图下缩略图更大，看图更直观
    };

    "org/nemo/list-view" = {
      default-visible-columns = [
        "name"
        "size"
        "type"
        "date_modified"
      ];
      default-column-order = [
        "name"
        "size"
        "type"
        "date_modified"
      ];
    };
  };
}
