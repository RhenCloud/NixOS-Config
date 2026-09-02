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
