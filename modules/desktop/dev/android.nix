{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.android;
in
{
  options.rhencloud.android.enable = mkEnableOption "Android development tools";
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # android-studio
      android-tools
      kotlin
    ];

    home.sessionVariables = {
      ANDROID_HOME = "$HOME/Android/Sdk";
      ANDROID_SDK_ROOT = "$HOME/Android/Sdk";
    };
  };
}
