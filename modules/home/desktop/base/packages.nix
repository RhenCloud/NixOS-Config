{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.hmBasePackages;

  # emote 退出时 GDK 写剪贴板会触发断管道警告，压制无影响的 stderr
  emote-wrapped = pkgs.writeShellApplication {
    name = "emote";
    runtimeInputs = [ pkgs.emote ];
    text = "exec ${lib.getExe pkgs.emote} \"$@\" 2>/dev/null";
  };
in
{
  options.rhencloud.hmBasePackages.enable = mkEnableOption "base desktop packages";
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      awww
      waypaper
      # dms-shell
      # linux-wallpaperengine
      waylyrics
      hyprpolkitagent
      clipse
      kdePackages.dolphin
      kdePackages.dolphin-plugins
      kdePackages.kservice
      shared-mime-info
      xdg-utils

      slurp
      grim
      satty
      shutter

      playerctl

      wl-clipboard
      cliphist
      copyq
      nwg-clipman

      krita
      kdePackages.gwenview

      hyfetch

      # thunar
      # thunar-volman
      # thunar-vcs-plugin
      # thunar-archive-plugin
      # thunar-media-tags-plugin
      # gvfs
      kdePackages.ark
      rar

      localsend
      # moonlight-qt

      splayer

      mission-center
      wayfreeze

      emote-wrapped
    ];
  };
}
