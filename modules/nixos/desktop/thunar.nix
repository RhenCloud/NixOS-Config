{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nufraw-thumbnailer
    ffmpegthumbnailer
  ];

  programs.thunar.plugins = with pkgs; [
    thunar-volman
    thunar-vcs-plugin
    thunar-archive-plugin
    thunar-media-tags-plugin
  ];

  programs.thunar.enable = true;
  programs.xfconf.enable = true;
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images
}
