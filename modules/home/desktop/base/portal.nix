_: {
  # Portal 配置由 NixOS 系统级模块统一管理 (modules/nixos/core/xdg.nix)
  # 这里只保留 xdg.mimeApps 的备用配置
  # xdg.mimeApps = {
  #   enable = true;
  #   defaultApplications = {
  #     "text/html" = [
  #       "zen.desktop"
  #       "zen-browser.desktop"
  #     ];
  #     "application/xhtml+xml" = [
  #       "zen.desktop"
  #       "zen-browser.desktop"
  #     ];
  #     "x-scheme-handler/http" = [
  #       "zen.desktop"
  #       "zen-browser.desktop"
  #     ];
  #     "x-scheme-handler/https" = [
  #       "zen.desktop"
  #       "zen-browser.desktop"
  #     ];
  #     "x-scheme-handler/about" = [
  #       "zen.desktop"
  #       "zen-browser.desktop"
  #     ];
  #     "x-scheme-handler/unknown" = [
  #       "zen.desktop"
  #       "zen-browser.desktop"
  #     ];

  #     "x-scheme-handler/terminal" = [ "kitty.desktop" ];
  #     "application/x-terminal-emulator" = [ "kitty.desktop" ];

  #     "inode/directory" = [ "thunar.desktop" ];
  #     "application/x-gnome-saved-search" = [ "thunar.desktop" ];
  #     "x-scheme-handler/file" = [ "thunar.desktop" ];
  #   };
  # };
}
