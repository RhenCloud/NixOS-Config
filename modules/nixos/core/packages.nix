{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.rhencloud.packages;

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
in {
  options.rhencloud.packages.enable = mkEnableOption "system packages";

  config = mkIf cfg.enable {
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
              (base.targetPkgs pkgs)
              ++ (with pkgs; [
                pkg-config
                ncurses
                libepoxy
              ]);
            profile = "export FHS=1";
            runScript = "bash";
            extraOutputsToInstall = [ "dev" ];
          }
        )
      )
    ];
  };
}
