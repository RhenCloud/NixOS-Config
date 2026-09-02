{ config, lib, ... }:
{
  home.stateVersion = lib.mkDefault "26.11";
  programs.home-manager.enable = true;
  programs.man.enable = false;

  my.isDesktop = true;

  rhencloud = {
    roles.dev.enable = true;

    fcitx5 = {
      enable = true;
      keytaoUserDict = ''
        李佳润	ljr
        泠云	lgyw
        联通性	ltx
        气笑了	qxl
        气笑	qx
      '';
    };

    # core
    browser.enable = true;
    git.enable = true;
    "hm-packages".enable = true;
    "hm-xdg".enable = true;
    "hm-wallpapers".enable = true;
    fish.enable = true;
    ghostty.enable = false;
    yazi.enable = true;
    fastfetch.enable = true;
    herdr.enable = true;

    # desktop
    hm-hyprland.enable = true;
    hm-niri.enable = true;
    hm-mango.enable = true;
    theme.enable = true;
    kitty.enable = true;
    chat.enable = true;
    misc.enable = true;
    hmBasePackages.enable = true;
    hmPolkit.enable = true;
    hmScreenshot.enable = true;
    hmSession.enable = true;
    foot.enable = true;
    tofi.enable = true;
    musicfox.enable = true;
    obsStudio.enable = true;
    prismlauncher.enable = true;
    noctalia.enable = true;
    vicinae.enable = true;
    hmStylix.enable = true;

    # service
    mpd.enable = true;
    clipse.enable = true;
    mprisence.enable = true;
  };
}
