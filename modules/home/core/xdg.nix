_:
{
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "$HOME/Desktop";
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    publicShare = "$HOME/Public";
    templates = "$HOME/Templates";
    videos = "$HOME/Videos";
  };

  # 设置鼠标指针大小以及字体 DPI
  xresources.properties = {
    "Xcursor.size" = 24;
    "Xft.dpi" = 96;
  };
}
