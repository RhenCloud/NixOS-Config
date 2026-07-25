{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.rhencloud.java;
in {
  options.rhencloud.java.enable = mkEnableOption "Java development tools";
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
    zulu17
    maven
    gradle
    jdt-language-server
    (writeShellScriptBin "java17" ''
      exec ${pkgs.zulu17}/bin/java "$@"
    '')
    (writeShellScriptBin "javac17" ''
      exec ${pkgs.zulu17}/bin/javac "$@"
    '')
    (writeShellScriptBin "java21" ''
      exec ${pkgs.zulu21}/bin/java "$@"
    '')
    (writeShellScriptBin "javac21" ''
      exec ${pkgs.zulu21}/bin/javac "$@"
    '')
    (writeShellScriptBin "use-jdk17" ''
      echo "Run this in fish: set -gx JAVA_HOME ${pkgs.zulu17}; set -gx PATH ${pkgs.zulu17}/bin \$PATH"
    '')
    (writeShellScriptBin "use-jdk21" ''
      echo "Run this in fish: set -gx JAVA_HOME ${pkgs.zulu21}; set -gx PATH ${pkgs.zulu21}/bin \$PATH"
    '')
  ];

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.zulu17}";
    JAVA17_HOME = "${pkgs.zulu17}";
    JAVA21_HOME = "${pkgs.zulu21}";
    };
  };
}
