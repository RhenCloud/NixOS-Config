{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.rhencloud.fcitx5;
in
{
  options.rhencloud.fcitx5 = {
    enable = lib.mkEnableOption "fcitx5 and rime custom config";

    extraRimeConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional Rime configuration values";
    };

    extraKeyTaoConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional keyt ao configuration values";
    };

    extraDictFiles = lib.mkOption {
      type = lib.types.listOf lib.types.attrsOf lib.types.path;
      default = [ ];
      description = "Extra custom dictionary files to install";
    };

    extraLuaFiles = lib.mkOption {
      type = lib.types.listOf lib.types.submodule (
        lib.types.submodule (
          { config, name, ... }: {
            options.name = lib.mkOption {
              type = lib.types.str;
              description = "Name (filename) for the Lua file";
            };
            options.source = lib.mkOption {
              type = lib.types.path;
              description = "Path to the Lua file content directory";
            };
          }
        )
      );
      default = [ ];
      description = "Extra Lua filter scripts to install";
    };

    extraAssortedFiles = lib.mkOption {
      type = lib.types.listOf lib.types.attrsOf lib.types.path;
      default = [ ];
      description = "Extra Rime config (YAML) files to install";
    };

    extraUserPhrases = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra user phrases (word code)";
    };

    extraYamlFiles = lib.mkOption {
      type = lib.types.listOf lib.types.attrsOf lib.types.path;
      default = [ ];
      description = "Extra YAML files to install";
    };

    extraUserDictPackages = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Additional custom dictionary packages to install";
    };

    extraCustomPhrases = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional custom phrases";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."fcitx5/rime".source = "${config.home.homeDirectory}/.local/share/fcitx5/rime";
    # 链接主题配置
    xdg.configFile."fcitx5/themes/dracula".source = ./fcitx5/themes/dracula;
    xdg.configFile."fcitx5/themes/default-dark".source = ./themes/default-dark;
    xdg.configFile."fcitx5/themes/default-light".source = ./themes/default-light;
    xdg.configFile."fcitx5/conf/classicui.conf".text = ''
      # 垂直候选列表
      Vertical Candidate List=False
      # 使用鼠标滚轮翻页
      WheelForPaging=True
      # 字体
      Font="Maple Mono NF CN 11"
      # 菜单字体
      MenuFont="Maple Mono NF CN 10"
      # 托盘字体
      TrayFont="Maple Mono NF CN 10"
      # 托盘标签轮廓颜色
      TrayOutlineColor=#000000
      # 托盘标签文本颜色
      TrayTextColor=#ffffff
      # 优先使用文字图标
      PreferTextIcon=True
      # 在图标中显示布局名称
      ShowLayoutNameInIcon=True
      # 使用输入法的语言来显示文字
      UseInputMethodLanguageToDisplayText=True
      # 主题
      Theme=default-dark
      # 深色主题
      DarkTheme=default-dark
      # 跟随系统浅色/深色设置
      UseDarkTheme=False
      # 当被主题和桌面支持时使用系统的重点色
      UseAccentColor=True
      # 在 X11 上针对不同屏幕使用单独的 DPI
      PerScreenDPI=False
      # 固定 Wayland 的字体 DPI
      ForceWaylandDPI=0
      # 在 Wayland 下启用分数缩放
      EnableFractionalScale=True
    '';

    home.packages = with pkgs; [ rime-keytao ] ++ cfg.extraUserDictPackages;

    home.activation.installRimeKeytao = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Install keytao via rime addon activation
      ${pkgs.rime-keytao}/bin/reinstall.sh
    '';

    home.activation.installRimeCustomConfig = lib.hm.dag.entryAfter [ "installRimeKeytao" ] ''
      rime_dir=$HOME/.local/share/fcitx5/rime

      mkdir -p "$rime_dir"

      # Copy keytao schemas from rime-keytao package
      ${pkgs.rime-keytao}/bin/reinstall.sh

      # Install custom user phrases
      ${pkgs.writeText "custom_phrase.txt.txt" cfg.extraCustomPhrases}
      ${lib.optionalString (cfg.extraUserPhrases != "") ''
        cat > "$rime_dir/custom_phrase.txt.txt" << EOF
                    ${cfg.extraUserPhrases}
                    EOF
      ''}

      # Install extra custom dictionaries
      ${lib.optionalString (cfg.extraDictFiles != [ ]) ''
        for file in ${
          lib.escapeShellArgs (map (n: cfg.extraDictFiles.${n}.path) (lib.attrNames cfg.extraDictFiles))
        }; do
          dest="$rime_dir/custom"
          dest="$dest/$(basename "$file")"
          cp -R "$file" "$dest"
        done
      ''}

      # Install extra YAML config files
      ${lib.optionalString (cfg.extraYamlFiles != [ ]) ''
        for file in ${
          lib.escapeShellArgs (map (n: cfg.extraYamlFiles.${n}.path) (lib.attrNames cfg.extraYamlFiles))
        }; do
          dest="$rime_dir/custom"
          mkdir -p "$dest"
          dest="$dest/$(basename "$file")"
          cp -R "$file" "$dest"
        done
      ''}

      # Install Lua filter scripts
      ${lib.optionalString (cfg.extraLuaFiles != [ ]) ''
        for filter in ${lib.escapeShellArgs (map (p: "${p.source}/${p.name}") cfg.extraLuaFiles)}; do
          src="$filter"
          dest="$rime_dir/custom"
          cp -R "$src" "$dest"
        done
      ''}

      echo "Rime custom config installed"
    '';
  };
}
