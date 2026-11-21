{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhen.fcitx5;

  # CloudKeyTao 的 Rime 数据包。这里**不做任何加工**：
  # 内联 schema、词库改名、剔除多方案，全在做包的那一侧（scripts/build.sh）。
  # 本模块只负责把它放到运行时目录里。
  cloudkeytao = inputs.cloudkeytao.packages.${pkgs.stdenv.hostPlatform.system}.rime-data;

  # 运行时目录里属于「用户数据」、绝不能被覆盖的东西。
  #
  # ⚠️ 这里只能列「产物里压根没有」的文件。若把产物里的表排除掉，
  #    extended 的 import_tables 会在部署时报
  #    `source file ... does not exist` 并整个表编译失败 —— 实测踩过。
  #    所以 cloudkeytao.local / cloudkeytao.custom.user 都必须留在产物里
  #    （作为空占位表），再由下面两类途径写入实际内容：
  #      * activation 无条件写 cloudkeytao.local
  #      * 定时器回流 cloudkeytao.custom.user（写回仓库，再进产物）
  userOwnedFiles = [
    "cloudkeytao-email.txt"
    "cloudkeytao-custom-phrase.txt"
    "custom_phrase.txt"
    "build"
    "user.yaml"
    "installation.yaml"
    "sync"
  ];

  # 从产物目录直接枚举要装的文件。
  #
  # 不在 Nix 里硬编码清单：上游加一个词库时这里不用跟着改，
  # 也就不存在「清单漂移」。目录里的子目录（lua/ opencc/）按递归处理。
  entries = builtins.readDir cloudkeytao;
  managedEntries = builtins.filter (
    n: !(builtins.elem n userOwnedFiles) && builtins.match ".*\\.userdb" n == null
  ) (builtins.attrNames entries);

  rimeDataFiles = lib.listToAttrs (
    map (name: {
      inherit name;
      value =
        let
          t = entries.${name};
        in
        {
          source = cloudkeytao + "/${name}";
          force = true;
        }
        // lib.optionalAttrs (t == "directory") { recursive = true; };
    }) managedEntries
  );

  # keytaoUserDict → 独立的 cloudkeytao.local 词库。
  #
  # 在 Nix 侧直接生成而不用 activation 脚本拼接：内容不可变、
  # 可被 Nix 跟踪，而且不需要写临时文件再 mv。
  # 与 cloudkeytao.user.dict.yaml 分开存：后者是产物，前者是本机私有。
  localDict = pkgs.writeText "cloudkeytao.local.dict.yaml" (
    ''
      # Rime dictionary
      # encoding: utf-8
      #
      # 由 NixOS-Config 的 rhen.fcitx5.keytaoUserDict 生成，勿手改。
      ---
      name: cloudkeytao.local
      version: "1.0"
      sort: by_weight
      use_preset_vocabulary: false
      columns:
        - text
        - code
        - weight
      ...
    ''
    + lib.concatMapStringsSep "\n" (
      line:
      let
        f = lib.splitString "\t" line;
        n = builtins.length f;
      in
      if n == 1 && line == "" then
        ""
      else if n == 2 then
        "${builtins.elemAt f 0}\t${builtins.elemAt f 1}\t999"
      else
        line
    ) (lib.splitString "\n" cfg.keytaoUserDict)
    + (if cfg.keytaoUserDict == "" then "" else "\n")
  );
in
{
  options.rhen.fcitx5 = {
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
        lib.types.submodule (_: {
          options.name = lib.mkOption {
            type = lib.types.str;
            description = "Name (filename) for the Lua file";
          };
          options.source = lib.mkOption {
            type = lib.types.path;
            description = "Path to the Lua file content directory";
          };
        })
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
      description = "额外用户词组（词组<Tab>编码[<Tab>词频]，词频默认 999）";
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

  options.rhen.fcitx5.enable = mkEnableOption "Fcitx5 RIME (HM)";

  config = mkIf cfg.enable {
    # 旧方案：programs.rime-keytao.enable = true;
    #
    # 上游那个 homeManagerModule 用 rsync 把 20+ 个方案的文件倒进运行时目录，
    # 然后用 activation 脚本 rm/sed/ln 打补丁 —— 两层动作抢同一批文件。
    # 现在已经完全不需要它：Rime 数据全部由下面的 xdg.dataFile 声明式安装。

    # 主题由 noctalia 从壁纸取色生成；深浅两套都指向 noctalia，
    # 否则跟随系统深色时会回退到 DarkTheme 指定的旧主题。
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
      Theme=dracula
      # 深色主题
      DarkTheme=dracula
      # 跟随系统浅色/深色设置
      UseDarkTheme=True
      # 当被主题和桌面支持时使用系统的重点色
      UseAccentColor=False
      # 在 X11 上针对不同屏幕使用单独的 DPI
      PerScreenDPI=False
      # 固定 Wayland 的字体 DPI
      ForceWaylandDPI=0
      # 在 Wayland 下启用分数缩放
      EnableFractionalScale=True
    '';

    # Rime 数据全部声明式安装。
    #
    # 这是本次改造的核心：旧方案是
    #   1. 上游 homeManagerModule 用 rsync 把 20+ 个方案文件倒进运行时目录
    #   2. 自己的 activation 再 rm / sed -i / ln -sf 去打补丁
    # 两层动作抢同一批文件，HOME_MANAGER_BACKUP_EXT 和部署顺序一变就坏。
    #
    # 现在只有一层：产物里是什么，装上就是什么。没有补丁脚本。
    xdg.dataFile = lib.mkMerge [
      (lib.mapAttrs' (name: v: lib.nameValuePair "fcitx5/rime/${name}" v) rimeDataFiles)
      {
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
      }
    ];

    # ── 本机私有数据 ────────────────────────────────────────────────────
    # 以下内容不属于方案本身（不适合放进公开产物），只在这台机器上生成。
    #
    # 必须 entryAfter [ "linkGeneration" ]：xdg.dataFile 的软链就是在那个
    # 阶段落的。若只写 writeBoundary，两者无先后关系，activation 写的
    # cloudkeytao.local 可能先写后被产物覆盖 —— 那就白写了。
    home.activation.installRimeLocalData = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      rime_dir=$HOME/.local/share/fcitx5/rime

      # 邮箱：quick_text 的 /email 从这里读
      printf '%s\n' '${config.rhen.user.email}' > "$rime_dir/cloudkeytao-email.txt"

      ${lib.optionalString (cfg.extraUserPhrases != "") ''
        {
          printf '%s\n' '${cfg.extraUserPhrases}'
        } \
          | ${pkgs.gawk}/bin/awk -F"\t" 'NF==2 {print $0 "\t999"} NF==3 {print}' \
          > "$rime_dir/custom_phrase.txt"
      ''}

      ${lib.optionalString (cfg.keytaoUserDict != "") ''
        # 内容由 Nix 侧生成（见 localDict），这里只负责放到位。
        # 产物里这个表是空的，但链接指向 nix store（只读），
        # 所以先删链接再写实际文件 —— 否则 install 会失败。
        rm -f "$rime_dir/cloudkeytao.local.dict.yaml"
        install -m644 ${localDict} "$rime_dir/cloudkeytao.local.dict.yaml"
      ''}

      echo "Rime 本机数据已写入"
    '';

    # 额外的词典 / YAML / Lua 文件（旧机制保留，但改成直白的 cp）
    home.activation.installRimeExtras = lib.hm.dag.entryAfter [ "installRimeLocalData" ] ''
      rime_dir=$HOME/.local/share/fcitx5/rime

      ${lib.optionalString (cfg.extraDictFiles != { }) ''
        for file in ${
          lib.escapeShellArgs (map (n: cfg.extraDictFiles.${n}.path) (lib.attrNames cfg.extraDictFiles))
        }; do
          mkdir -p "$rime_dir/custom"
          cp -R "$file" "$rime_dir/custom/$(basename "$file")"
        done
      ''}

      ${lib.optionalString (cfg.extraYamlFiles != { }) ''
        for file in ${
          lib.escapeShellArgs (map (n: cfg.extraYamlFiles.${n}.path) (lib.attrNames cfg.extraYamlFiles))
        }; do
          mkdir -p "$rime_dir/custom"
          cp -R "$file" "$rime_dir/custom/$(basename "$file")"
        done
      ''}

      ${lib.optionalString (cfg.extraLuaFiles != [ ]) ''
        for src in ${lib.escapeShellArgs (map (p: "${p.source}/${p.name}") cfg.extraLuaFiles)}; do
          mkdir -p "$rime_dir/custom"
          cp -R "$src" "$rime_dir/custom/"
        done
      ''}
    '';

    # 把用户自造的词固化回仓库（旧机制保留，仅改为新文件名）
    systemd.user.services.cloudkeytao-custom-phrase-sync = {
      Unit.Description = "固化键道动态造词";
      Service = {
        Type = "oneshot";
        WorkingDirectory = "%h/Project/NixOS-Config";
        ExecStart = pkgs.writeShellScript "cloudkeytao-custom-phrase-sync" ''
          ${pkgs.python3}/bin/python3 ${../../../scripts/sync-keytao-custom-phrases.py} \
            "$HOME/.local/share/fcitx5/rime/cloudkeytao-custom-phrase.txt" \
            modules/desktop/fcitx5/cloudkeytao.custom.user.dict.yaml
        '';
      };
    };

    systemd.user.timers.cloudkeytao-custom-phrase-sync = {
      Unit.Description = "定期固化键道动态造词";
      Timer = {
        OnCalendar = "weekly";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
