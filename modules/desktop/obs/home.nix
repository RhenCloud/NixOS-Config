{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.obsStudio;
in
{
  options.rhencloud.obsStudio.enable = mkEnableOption "OBS Studio";
  config = mkIf cfg.enable {
    programs.obs-studio = {
      enable = true;

      # 启用可选的 Nvidia 硬件加速
      package = pkgs.obs-studio.override {
        cudaSupport = true;
      };

      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
        obs-vaapi # 可选的 AMD 硬件加速
        obs-gstreamer
        obs-vkcapture
      ];
    };
  };
}
