{ lib, ... }:
{
  home.stateVersion = lib.mkDefault "26.11";
  programs.home-manager.enable = true;
  programs.man.enable = false;

  my.isDesktop = true;

  rhencloud = {
    fcitx5 = {
      enable = true;
      keytaoUserDict = ''
        泠云	lgyw
        李佳润	ljr
      '';
    };

    # core
    browser.enable = true;
    git.enable = true;
    "hm-packages".enable = true;
    "hm-xdg".enable = true;
    fish.enable = true;
    ghostty.enable = true;
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

    # dev
    c.enable = true;
    android.enable = true;
    golang.enable = true;
    java.enable = true;
    lucy.enable = true;
    node.enable = true;
    python.enable = true;
    rust.enable = true;
    hmDevPackages.enable = true;
    certs.enable = true;
    opencode.enable = true;
    emacs.enable = false;
    nvf.enable = true;
    helix.enable = true;
    hmOpenAgent.enable = true;
    aider.enable = true;

    # service
    mpd.enable = true;
    clipse.enable = true;
    mprisence.enable = true;
  };
}
