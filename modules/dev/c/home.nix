{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.c;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      clang
      clang-tools
      lldb
      llvm
      xmake
      gnumake
      cmake
      ninja
      pkg-config
      mold
    ];

    home.sessionVariables = {
      CC = "clang";
      CXX = "clang++";
    };
  };
}
