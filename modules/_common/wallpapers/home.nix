{ config, lib, ... }:
let
  wallpapersDir = config.home.homeDirectory + "/Project/NixOS-Config/wallpapers";
in
{
  options.rhen.hm-wallpapers.enable = lib.mkEnableOption "wallpapers symlink to ~/Pictures/Wallpapers";

  config = lib.mkIf config.rhen.hm-wallpapers.enable {
    home.file."Pictures/Wallpapers".source = config.lib.file.mkOutOfStoreSymlink wallpapersDir;
  };
}
