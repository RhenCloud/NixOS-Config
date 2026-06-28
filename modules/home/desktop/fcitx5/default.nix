{ config, lib, pkgs, ... }:
let
  cfg = config.rhencloud.fcitx5;
in
{
  options.rhencloud.fcitx5 = {
    enable = lib.mkEnableOption "fcitx5 and rime custom config";

    extraRimeConfig = lib.mkOption {
      type = lib.types submodule {
        imports = [ (lib.types.submodule {
          freeformType = lib.types.attrs;
        }) ];
        description = "Extra Rime config values for keytao schema";
      };
      default = { };
      example = {
        punctuator = { };
        switches = [ ];
      };
      description = "Additional Rime configuration values";
    };

    extraKeyTaoConfig = lib.mkOption {
      type = lib.types submodule {
        imports = [ (lib.types.submodule {
          freeformType = lib.types.attrs;
        }) ];
        description = "Extra Keyt ao specific config values";
      };
      default = { };
      example = {
        punctuator = { };
        ascii_composer = { };
      };
      description = "Additional keyt ao configuration values";
    };

    extraDictFiles = lib.mkOption {
      type = lib.types.listOf lib.types.attrsOf lib.types.path;
      default = [ ];
      example = [ {
        name = "custom";
        path = pkgs.writeText "custom.dict.yaml" ''
          custom 词
        '';
      } ];
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
      example = [ {
        name = "emoji_filter.lua";
        source = ./reduce_emoji_filter.lua;
      } ];
      description = "Extra Lua filter scripts to install";
    };

    extraAssortedFiles = lib.mkOption {
      type = lib.types.listOf lib.types.attrsOf lib.types.path;
      default = [ ];
      example = [ {
        name = "default.custom.yaml";
        path = ./rime-config/default.custom.yaml;
      } ];
      description = "Extra Rime config (YAML) files to install";
    };

    extraUserPhrases = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = ""
        "customa  aaaa
        customb  bbbb
        customc  cccc
      "";
      description = "Extra user phrases (word code)";
    };

    extraYamlFiles = lib.mkOption {
      type = lib.types.listOf lib.types.attrsOf lib.types.path;
      default = [ ];
      example = [ {
        name = "keytao.extended.dict.yaml";
        path = ./rime-config/extended.dict.yaml;
      } ];
      description = "Extra YAML files to install";
    };

    extraUserDictPackages = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      example = [ pkgs.ice2keytao ];
      description = "Additional custom dictionary packages to install";
    };

    extraCustomPhrases = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = "泠云=lgyw";
      description = "Additional custom phrases";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."fcitx5/rime".source = "${
      config.home.homeDirectory
    }/.local/share/fcitx5/rime";

    home.packages = with pkgs; [ rime-keytao ] ++ cfg.extraUserDictPackages;

    home.activation.installRimeKeytao =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Install keytao via rime addon activation
        ${pkgs.rime-keytao}/bin/reinstall.sh
      '';

    home.activation.installRimeCustomConfig =
      lib.hm.dag.entryAfter [ "installRimeKeytao" ] ''
        rime_dir=$HOME/.local/share/fcitx5/rime

        mkdir -p "$rime_dir"

        # Install custom user phrases
        ${pkgs.writeText "custom_phrase.txt.txt" cfg.extraCustomPhrases}
        ${lib.optionalString (cfg.extraUserPhrases != "") 
          ''cat > "$rime_dir/custom_phrase.txt.txt" << 'EOF'
            ${cfg.extraUserPhrases}
            EOF
        ''}

        # Install extra custom dictionaries
        for file in '${lib.strings.concatStringsSep "'\'' '"'"'"' ${lib.strings.mapStrings (n: cfg.extraDictFiles.${n}.path) (lib.attrNames cfg.extraDictFiles)} ''}; do
          dest="$rime_dir/custom"
          dest="$dest/$(basename "$file")"
          cp -R "$file" "$dest"
        done

        # Install extra YAML config files
        for file in ${lib.escapeShellArgs (map (n: cfg.extraYamlFiles.${n}.path) (lib.attrNames cfg.extraYamlFiles))}; do
          dest="$rime_dir/custom"
          mkdir -p "$dest"
          dest="$dest/$(basename "$file")"
          cp -R "$file" "$dest"
        done

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
