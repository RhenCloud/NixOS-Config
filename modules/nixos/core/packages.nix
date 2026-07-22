{ pkgs, ... }:
let
  kleopatra-wrapped = pkgs.symlinkJoin {
    name = "kleopatra-wrapped";
    paths = [ pkgs.kdePackages.kleopatra ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/kleopatra \
        --set QT_LOGGING_RULES "kf5.kcoreaddons.warning=false" \
        --set QT_QPA_PLATFORM "wayland" \
        --set QT_NO_GLIB "1"
    '';
  };

  # gparted-wrapped = pkgs.writeShellScriptBin "gparted" ''
  #   exec pkexec env \
  #     DISPLAY="$DISPLAY" \
  #     XAUTHORITY="$XAUTHORITY" \
  #     WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
  #     ${pkgs.gparted}/bin/gparted "$@"
  # '';
in
{
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    android-tools
    git
    gnupg
    sops
    vim
    curl
    wget
    udisks
    neovim
    mpd
    daed
    # gparted-wrapped
    gparted-full
    nixpkgs-fmt
    mihomo
    kleopatra-wrapped
    gsettings-desktop-schemas
    pcsc-tools
    opensc
    usbutils
    tree
    nixd
    unzip
    ffmpeg
    fd
    nix-du
    nix-direnv
    deadnix
    nil
    jq
    bat
    ntfs3g
    file
    geo
    cacert
    home-manager

    # 创建 `fhs` 命令，用于运行依赖传统 FHS 目录结构的软件
    (
      let
        base = pkgs.appimageTools.defaultFhsEnvArgs;
      in
      pkgs.buildFHSEnv (
        base
        // {
          name = "fhs";
          targetPkgs =
            pkgs:
            # pkgs.buildFHSEnv 只提供最小 FHS 环境，使用 appimageTools 补充常见依赖
            (base.targetPkgs pkgs)
            ++ (with pkgs; [
              pkg-config
              ncurses
              libepoxy
              # 如果 FHS 程序还有其他依赖，在这里补充
            ]);
          profile = "export FHS=1";
          runScript = "bash";
          extraOutputsToInstall = [ "dev" ];
        }
      )
    )
  ];
}
