{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.rhencloud.fcitx5;
  rimeKeytaoPkg = inputs.rime-keytao.packages.${pkgs.system}.default;
in
{
  options.rhencloud.fcitx5 = {
    extraRimeConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional Rime configuration values";
    };

    extraKeyTaoConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional keytao configuration values";
    };

    extraDictFiles = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.path = lib.mkOption {
            type = lib.types.path;
          };
        }
      );
      default = { };
      description = "Extra custom dictionary files to install";
    };

    extraLuaFiles = lib.mkOption {
      type = lib.types.listOf (
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
      type = lib.types.listOf (lib.types.attrsOf lib.types.path);
      default = [ ];
      description = "Extra Rime config (YAML) files to install";
    };

    extraUserPhrases = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra user phrases (word code)";
    };

    extraYamlFiles = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.path = lib.mkOption {
            type = lib.types.path;
          };
        }
      );
      default = { };
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

    keytaoUserDict = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "键道用户词典追加条目（词组<Tab>编码）";
    };
  };

  config = {
    # 使用 rime-keytao 自身提供的 HM 模块来安装
    programs.rime-keytao.enable = true;

    # 主题文件放到 ~/.local/share/fcitx5/themes/（fcitx5-configtool 能识别的路径）
    xdg.dataFile."fcitx5/themes/dracula" = {
      source = ./fcitx5/themes/dracula;
      recursive = true;
    };
    xdg.dataFile."fcitx5/themes/default-dark" = {
      source = ./themes/default-dark;
      recursive = true;
    };
    xdg.dataFile."fcitx5/themes/default-light" = {
      source = ./themes/default-light;
      recursive = true;
    };

    # classicui.conf 放到 ~/.config/fcitx5/conf/classicui.conf
    # xdg.configFile."fcitx5/conf/classicui.conf".text = ''
    #   # 垂直候选列表
    #   Vertical Candidate List=False
    #   # 使用鼠标滚轮翻页
    #   WheelForPaging=True
    #   # 字体
    #   Font="Maple Mono NF CN 11"
    #   # 菜单字体
    #   MenuFont="Maple Mono NF CN 10"
    #   # 托盘字体
    #   TrayFont="Maple Mono NF CN 10"
    #   # 托盘标签轮廓颜色
    #   TrayOutlineColor=#000000
    #   # 托盘标签文本颜色
    #   TrayTextColor=#ffffff
    #   # 优先使用文字图标
    #   PreferTextIcon=True
    #   # 在图标中显示布局名称
    #   ShowLayoutNameInIcon=True
    #   # 使用输入法的语言来显示文字
    #   UseInputMethodLanguageToDisplayText=True
    #   # 主题
    #   Theme=default-dark
    #   # 深色主题
    #   DarkTheme=default-dark
    #   # 跟随系统浅色/深色设置
    #   UseDarkTheme=False
    #   # 当被主题和桌面支持时使用系统的重点色
    #   UseAccentColor=True
    #   # 在 X11 上针对不同屏幕使用单独的 DPI
    #   PerScreenDPI=False
    #   # 固定 Wayland 的字体 DPI
    #   ForceWaylandDPI=0
    #   # 在 Wayland 下启用分数缩放
    #   EnableFractionalScale=True
    # '';

    home.activation.installRimeLateConfig = ''
            rime_dir=$HOME/.local/share/fcitx5/rime
            mkdir -p "$rime_dir/lua"

            # 覆盖自定义 YAML（rime-keytao 同步的版本无自定义修改）
            cp -f ${./default.custom.yaml} "$rime_dir/default.custom.yaml"
            cp -f ${./keytao.custom.yaml} "$rime_dir/keytao.custom.yaml"

            # 覆盖 Lua 脚本（rime-keytao rsync 会删除 xdg.dataFile 的链接，所以在此部署）
            cp -f ${./rime/lua/reduce_emoji_filter.lua} "$rime_dir/lua/reduce_emoji_filter.lua"
            cp -f ${./rime/lua/select_character.lua} "$rime_dir/lua/select_character.lua"

            # 清理旧版 xmjd6 残留文件
            for f in xmjd6 liangfen pinyin_simp; do
              rm -f "$rime_dir/$f"*.*
            done
            rm -rf "$rime_dir/lua/xmjd6"* "$rime_dir/opencc/xmjd6" 2>/dev/null || true

            # 追加 require 到 rime.lua
            if [ -f "$rime_dir/rime.lua" ]; then
              # 旧版存根清理（如果存在）
              if grep -q "Stub for reduce_emoji_filter" "$rime_dir/rime.lua" 2>/dev/null; then
                sed -i '/-- Stub for reduce_emoji_filter/,/reduce_emoji_processor = reduce_emoji_filter/d' "$rime_dir/rime.lua"
              fi
              if ! grep -q "select_character" "$rime_dir/rime.lua" 2>/dev/null; then
                cat >> "$rime_dir/rime.lua" << 'LUAEOF'

      -- reduce_emoji_filter: 降低 emoji 在候选项的位置
      reduce_emoji_filter = require("reduce_emoji_filter")

      -- select_character: 首/末字选择
      select_character = require("select_character")
      LUAEOF
              fi
            fi

            ${lib.optionalString (cfg.extraUserPhrases != "") ''
              cat > "$rime_dir/custom_phrase.txt" << EOF
              ${cfg.extraUserPhrases}
              EOF
            ''}

            ${lib.optionalString (cfg.keytaoUserDict != "") ''
              if [ -f "$rime_dir/keytao.user.dict.yaml" ]; then
                sed -i '/^# >>> Nix managed$/,/^# <<< Nix managed$/d' "$rime_dir/keytao.user.dict.yaml"
                { printf '%s\n' "# >>> Nix managed"; printf '%s\n' '${cfg.keytaoUserDict}' | awk -F"\t" 'NF==2 {print $0 "\t999"} NF!=2 {print}'; printf '%s\n' "# <<< Nix managed"; } >> "$rime_dir/keytao.user.dict.yaml"
              fi
            ''}

            # 部署 ice2keytao（从 rime-ice 转换的词库）
            python3 ${./../../../../scripts/convert-rime-ice-to-keytao.py} \
              "${pkgs.rime-ice}/share/rime-data/cn_dicts" \
              "${rimeKeytaoPkg}/share/rime-data/keytao.phrase.dict.yaml" \
              "${rimeKeytaoPkg}/share/rime-data/keytao.single.dict.yaml" \
              "$rime_dir/ice2keytao.dict.yaml"
            if [ -f "$rime_dir/keytao.extended.dict.yaml" ]; then
              if ! grep -q "ice2keytao" "$rime_dir/keytao.extended.dict.yaml" 2>/dev/null; then
                sed -i '/^\.\.\.$/a\  - ice2keytao' "$rime_dir/keytao.extended.dict.yaml"
              fi
            fi

            ${lib.optionalString (cfg.extraDictFiles != { }) ''
              for file in ${
                lib.escapeShellArgs (map (n: cfg.extraDictFiles.${n}.path) (lib.attrNames cfg.extraDictFiles))
              }; do
                dest="$rime_dir/custom"
                dest="$dest/$(basename "$file")"
                cp -R "$file" "$dest"
              done
            ''}

            ${lib.optionalString (cfg.extraYamlFiles != { }) ''
              for file in ${
                lib.escapeShellArgs (map (n: cfg.extraYamlFiles.${n}.path) (lib.attrNames cfg.extraYamlFiles))
              }; do
                dest="$rime_dir/custom"
                mkdir -p "$dest"
                dest="$dest/$(basename "$file")"
                cp -R "$file" "$dest"
              done
            ''}

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
