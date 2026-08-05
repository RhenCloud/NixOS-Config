{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.fcitx5;
  rimeKeytaoPkg = inputs.rime-keytao.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
          _: {
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

  options.rhencloud.fcitx5.enable = mkEnableOption "Fcitx5 RIME (HM)";

  config = mkIf cfg.enable {
    programs.rime-keytao.enable = true;

    xdg.dataFile = {
      "fcitx5/themes/dracula" = {
        source = ./fcitx5/themes/dracula;
        recursive = true;
      };
      "fcitx5/themes/default-dark" = {
        source = ./themes/default-dark;
        recursive = true;
      };
      "fcitx5/themes/default-light" = {
        source = ./themes/default-light;
        recursive = true;
      };
      "fcitx5/rime/default.custom.yaml" = {
        source = ./default.custom.yaml;
        force = true;
      };
      "fcitx5/rime/keytao.custom.yaml" = {
        source = ./keytao.custom.yaml;
        force = true;
      };
      "fcitx5/rime/lua/reduce_emoji_filter.lua" = {
        source = ./rime/lua/reduce_emoji_filter.lua;
      };
      "fcitx5/rime/lua/select_character.lua" = {
        source = ./rime/lua/select_character.lua;
      };
    };

    home.activation.installRimeLateConfig = lib.hm.dag.entryAfter [ "installRimeKeytao" ] ''
            rime_dir=$HOME/.local/share/fcitx5/rime

            rm -f "$rime_dir/default.custom.yaml"
            ln -sf ${./default.custom.yaml} "$rime_dir/default.custom.yaml"
            rm -f "$rime_dir/keytao.custom.yaml"
            ln -sf ${./keytao.custom.yaml} "$rime_dir/keytao.custom.yaml"

            for f in xmjd6 liangfen pinyin_simp; do
              rm -f "$rime_dir/$f"*.*
            done
            rm -rf "$rime_dir/lua/xmjd6"* "$rime_dir/opencc/xmjd6" 2>/dev/null || true

            if [ -f "$rime_dir/rime.lua" ]; then
              if grep -q "Stub for reduce_emoji_filter" "$rime_dir/rime.lua" 2>/dev/null; then
                sed -i '/-- Stub for reduce_emoji_filter/,/reduce_emoji_processor = reduce_emoji_filter/d' "$rime_dir/rime.lua"
              fi
              if ! grep -q "select_character" "$rime_dir/rime.lua" 2>/dev/null; then
                cat >> "$rime_dir/rime.lua" << 'LUAEOF'

      reduce_emoji_filter = require("reduce_emoji_filter")
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
                { printf '%s\n' "# >>> Nix managed"; printf '%s\n' '${cfg.keytaoUserDict}' | ${pkgs.gawk}/bin/awk -F"\t" 'NF==2 {print $0 "\t999"} NF!=2 {print}'; printf '%s\n' "# <<< Nix managed"; } >> "$rime_dir/keytao.user.dict.yaml"
              fi
            ''}

            ${pkgs.python3}/bin/python3 ${./../../../../scripts/convert-rime-ice-to-keytao.py} \
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
