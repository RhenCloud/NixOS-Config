{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.musicfox;
in
{
  options.rhencloud.musicfox.enable = mkEnableOption "Go Musicfox music player";
  config = mkIf cfg.enable {
    xdg.configFile = {
      "go-musicfox/config.toml" = {
        source = ./config.toml;
      };
    };
    # home.file.".local/share/go-musicfox/cookie".source = ./cookie;
    # home.file.".local/share/go-musicfox/cookie" = {
    # text = builtins.readFile config.age.secrets.musicfoxCookie.path;
    # onChange = "cp ${config.age.secrets.musicfoxCookie.path} .local/share/go-musicfox/cookie";
    # };
    # .source = builtins.toString config.age.secrets.musicfoxCookie.path;
    home.packages = with pkgs; [
      go-musicfox
      waylyrics
      mpv-unwrapped
    ];
  };
}
