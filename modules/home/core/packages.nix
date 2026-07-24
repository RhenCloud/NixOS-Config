{ pkgs, ... }: {
  home.packages = with pkgs; [
    nh
    fzf
    perl
    themechanger
    google-chrome
    eza
    nixfmt
    keymapper
    wemeet
    qbittorrent
    blender
    aliyunpan
    # splayer
    ripgrep
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
}
