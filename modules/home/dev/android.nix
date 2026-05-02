{ pkgs, ... }:
{
  home.packages = with pkgs; [
    android-studio
    android-tools
    kotlin
  ];

  home.sessionVariables = {
    ANDROID_HOME = "$HOME/Android/Sdk";
    ANDROID_SDK_ROOT = "$HOME/Android/Sdk";
  };
}
