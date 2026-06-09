{
  pkgs,
  inputs,
  ...
}:

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

  home.packages = with pkgs; [
    fzf
    sptk
    perl
    themechanger
    google-chrome
    eza
    nixfmt
    keymapper
    inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.lwe
    wemeet
    qbittorrent
    blender
    aliyunpan
    splayer
    ripgrep
    # If you prefer Sequoia, add it here; keeping system `gnupg` avoids conflicts
    # Use sequoia-chameleon-gnupg (provides a gpg-compatible wrapper)
    # and avoid also installing `gnupg` to prevent conflicting `/bin/gpg` files.
    asciinema
    (writeShellScriptBin "gpg-card-ssh-pubkey" ''
      set -euo pipefail
      if [ "$#" -ne 1 ]; then
        echo "Usage: gpg-card-ssh-pubkey <OPENPGP_FINGERPRINT>" >&2
        exit 1
      fi

      gpg --export-ssh-key "$1"
    '')
  ];

  programs.chromium = {
    enable = true;
    package = pkgs.brave;
    extensions = [
      "bgnkhhnnamicmpeenaelnjfhikgbkllg" # AdGuard
      "ndcooeababalnlpkfedmmbbbgkljhpjf" # 脚本猫
      "lildghglkgcoanblbmenbefhnhifghjj" # BewlyBewly! Ave Mujica
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "jlgkpaicikihijadgifklkbpdajbkhjo" # crxMouse
    ];
    # commandLineArgs = [
    #   "--disable-features=WebRtcAllowInputVolumeAdjustment"
    # ];
  };

  programs.vscode = {
    enable = true;
    # package = pkgs.vscode.fhs;
  };

  # git 相关配置
  programs.git = {
    enable = true;
    signing = {
      signByDefault = true;
      format = "openpgp";
    };
    settings = {
      gpg.program = "${pkgs.gnupg}/bin/gpg";
      credential.helper = "store";
      commit.gpgsign = true;
      tag.gpgSign = true;
      init.defaultBranch = "main";
      user = {
        name = "RhenCloud";
        email = "i@rhen.cloud";
        signingKey = "REDACTED-59acd1c2";
      };
    };
  };

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    enableScDaemon = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-gtk2;
    defaultCacheTtl = 1800;
    maxCacheTtl = 7200;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      identityAgent = "~/.gnupg/S.gpg-agent.ssh";
    };
  };

  home.file.".gnupg/scdaemon.conf".text = ''
    disable-ccid
    pcsc-shared
  '';

  programs.obs-studio = {
    enable = true;

    # optional Nvidia hardware acceleration
    package = (
      pkgs.obs-studio.override {
        cudaSupport = true;
      }
    );

    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vaapi # optional AMD hardware acceleration
      obs-gstreamer
      obs-vkcapture
    ];
  };

  # home.activation.copyDesktopFiles = lib.hm.dag.entryAfter [ "installPackages" ] ''
  #   if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then

  #     if [ ! -d "${config.home.homeDirectory}/.local/share/applications" ]; then
  #       mkdir "${config.home.homeDirectory}/.local/share/applications"
  #     fi

  #     if [ -d "${config.home.homeDirectory}/.local/share/applications/nix" ]; then
  #       rm -rf "${config.home.homeDirectory}/.local/share/applications/nix"
  #     fi

  #     ln -sf "${config.home.homeDirectory}/.nix-profile/share/applications" \
  #       ${config.home.homeDirectory}/.local/share/applications/nix

  #   fi
  # '';

}
