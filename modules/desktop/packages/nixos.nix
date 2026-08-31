{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.desktopPackages;

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
in
{
  options.rhencloud.desktopPackages.enable = mkEnableOption "desktop system packages";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      android-tools
      gparted-full
      mpd
      daed
      neovim
      kleopatra-wrapped
      gsettings-desktop-schemas
      ffmpeg
      geo

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
