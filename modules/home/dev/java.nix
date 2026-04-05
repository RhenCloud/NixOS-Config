{ pkgs, ... }:
{
  home.packages = with pkgs; [
    zulu
    maven
    gradle
    jdt-language-server
  ];

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.zulu}/lib/openjdk";
  };
}
