{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhen.theme;

  # Dracula 统一主题：
  #   GTK  -> dracula-theme (share/themes/Dracula, Ant 系变体)
  #   Qt   -> Kvantum 样式 + Dracula Kvantum 主题（dracula-theme 自带 share/Kvantum/Dracula）
  #   KDE  -> 通过 kdeglobals 引用 dracula-theme 的 share/color-schemes/Dracula.colors，
  #           让 Dolphin/Ark/Krita 等 KF6 原生界面（不走 portal 的部分）也吃到 Dracula 配色
  #   图标 -> Colloid（扁平干净风格，深色变体与 Dracula 暗色底更搭）
  # noctalia 换壁纸时仍会重写 ~/.config/gtk-{3,4}.0/noctalia.css（extraCss 保留 @import）。

  # kwriteconfig6 删除单个键 = "--delete"（在 HM 里把值设成 null）。
  # 历史上 kdeglobals 内联过一份 Breeze 浅色 [Colors:*]/[WM] 段，
  # 不清掉的话会覆盖 ColorScheme=Dracula，这里逐个删除。
  # 未列出的键（如 [KFileDialog Settings] 的视图偏好、[PreviewSettings]）不受影响。
  standardColorKeys = [
    "BackgroundAlternate"
    "BackgroundNormal"
    "DecorationFocus"
    "DecorationHover"
    "ForegroundActive"
    "ForegroundInactive"
    "ForegroundLink"
    "ForegroundNegative"
    "ForegroundNeutral"
    "ForegroundNormal"
    "ForegroundPositive"
    "ForegroundVisited"
  ];

  colorEffectKeys = [
    "ChangeSelectionColor"
    "Color"
    "ColorAmount"
    "ColorEffect"
    "ContrastAmount"
    "ContrastEffect"
    "Enable"
    "IntensityAmount"
    "IntensityEffect"
  ];

  deleteKeys = keys: listToAttrs (map (key: nameValuePair key null) keys);

  kdeglobalsSettings = {
    General = {
      ColorScheme = "Dracula";
      ColorSchemeHash = null;
      # KDE 应用（Dolphin 等）的图标主题，缺省会退回 Breeze
      IconTheme = "Colloid-Dark";
    };
    KDE.contrast = 5;
  }
  // {
    "ColorEffects:Disabled" = deleteKeys colorEffectKeys;
    "ColorEffects:Inactive" = deleteKeys colorEffectKeys;
    "Colors:Button" = deleteKeys standardColorKeys;
    "Colors:Complementary" = deleteKeys standardColorKeys;
    "Colors:Header" = deleteKeys standardColorKeys // {
      # 对应 kdeglobals 里的 [Colors:Header][Inactive] 段
      Inactive = deleteKeys standardColorKeys;
    };
    "Colors:Selection" = deleteKeys standardColorKeys;
    "Colors:Tooltip" = deleteKeys standardColorKeys;
    "Colors:View" = deleteKeys standardColorKeys;
    "Colors:Window" = deleteKeys standardColorKeys;
    WM = deleteKeys [
      "activeBackground"
      "activeBlend"
      "activeForeground"
      "inactiveBackground"
      "inactiveBlend"
      "inactiveForeground"
    ];
  };

  # qt5ct / qt6ct 共用同一份外观（调色板交给 Kvantum，故不设 custom_palette）。
  qtctSettings = {
    Appearance = {
      style = "kvantum";
      icon_theme = "Colloid-Dark";
      # 关键：Qt 应用的文件选择框走 xdg portal，
      # 由 modules/_common/xdg 的路由统一交给 GTK portal 的 FileChooser 实现
      standard_dialogs = "xdgdesktopportal";
    };
    Fonts = {
      # qtct 用 QFont::fromString 解析，需要带引号的字符串
      general = builtins.toJSON "Maple Mono NF CN,11";
      fixed = builtins.toJSON "Maple Mono NF CN,11";
    };
  };
in
{
  options.rhen.theme.enable = mkEnableOption "desktop theme (GTK/Qt)";

  config = mkIf cfg.enable {
    home = {
      packages = [
        pkgs.dracula-theme # GTK/Kvantum/KDE 配色/cursor/plasma 全家桶
        pkgs.colloid-icon-theme
      ];
      pointerCursor = {
        enable = true;
        gtk.enable = true;
        x11.enable = true;
        size = 24;
        package = pkgs.rose-pine-cursor;
        name = "BreezeX-RosePine-Linux";
      };
      sessionVariables = {
        GTK_USE_PORTAL = "1";
        GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/glib-2.0/schemas";
      };
    };

    qt = {
      enable = true;
      # HM 会据此安装 qt5ct/qt6ct + kvantum 样式插件（qt/qtstyleplugin-kvantum 双版本），
      # 并设置 QT_QPA_PLATFORMTHEME=qt5ct、QT_STYLE_OVERRIDE=kvantum
      platformTheme.name = "qtct";
      style.name = "kvantum";

      qt5ctSettings = qtctSettings;
      qt6ctSettings = qtctSettings;

      kvantum = {
        enable = true;
        settings.General.theme = "Dracula";
        themes = [ pkgs.dracula-theme ];
      };

      # activation 时用 kwriteconfig6 增量管理 ~/.config/kdeglobals
      # （qt.kde.settings 的顶层键是配置文件名）
      kde.settings.kdeglobals = kdeglobalsSettings;
    };

    gtk = {
      enable = true;
      # 全局界面字体（gtk2/gtk3/gtk4 继承）
      font = {
        name = "Maple Mono NF CN";
        size = 11;
      };
      theme = {
        name = "Dracula";
        package = pkgs.dracula-theme;
      };
      iconTheme = {
        name = "Colloid-Dark";
        package = pkgs.colloid-icon-theme;
      };
      # noctalia 生成的调色板，换壁纸时自动重写同目录下的 noctalia.css
      gtk3.extraCss = ''@import url("noctalia.css");'';
      gtk4 = {
        theme = {
          name = "Dracula";
          package = pkgs.dracula-theme;
        };
        extraCss = ''@import url("noctalia.css");'';
      };
    };
  };
}
