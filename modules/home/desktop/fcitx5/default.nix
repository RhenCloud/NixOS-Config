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
      type = lib.types.attrsOf (lib.types.submodule {
        options.path = lib.mkOption {
          type = lib.types.path;
        };
      });
      default = { };
      description = "Extra custom dictionary files to install";
    };

    extraLuaFiles = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule (
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
      ));
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
      type = lib.types.attrsOf (lib.types.submodule {
        options.path = lib.mkOption {
          type = lib.types.path;
        };
      });
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
    xdg.configFile."fcitx5/conf/classicui.conf".text = ''
      VerticalCandidateList=False
      WheelForPaging=True
      Font="Maple Mono NF CN 11"
      MenuFont="Maple Mono NF CN 10"
      TrayFont="Maple Mono NF CN 10"
      TrayOutlineColor=#000000
      TrayTextColor=#ffffff
      PreferTextIcon=True
      ShowLayoutNameInIcon=True
      UseInputMethodLanguageToDisplayText=True
      Theme=default-dark
      DarkTheme=default-dark
      UseDarkTheme=False
      UseAccentColor=True
      PerScreenDPI=False
      ForceWaylandDPI=0
      EnableFractionalScale=True
    '';

    # Lua 脚本（放到 rime/lua/ 下，供 rime.lua 的 require 加载）
    xdg.dataFile."fcitx5/rime/lua/reduce_emoji_filter.lua" = {
      source = ./rime/lua/reduce_emoji_filter.lua;
      force = true;
    };
    xdg.dataFile."fcitx5/rime/lua/select_character.lua" = {
      source = ./rime/lua/select_character.lua;
      force = true;
    };

    home.activation.installRimeLateConfig = ''
      rime_dir=$HOME/.local/share/fcitx5/rime
      mkdir -p "$rime_dir"

      # 覆盖 default.custom.yaml（rime-keytao 同步后生效）
      cp -f ${./default.custom.yaml} "$rime_dir/default.custom.yaml"

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
          reduce_emoji_translator = reduce_emoji_filter
          reduce_emoji_processor = reduce_emoji_filter

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
