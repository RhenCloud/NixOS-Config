{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.hm-packages;
in
{
  options.rhencloud.hm-packages.enable = mkEnableOption "home packages";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nh
      fzf
      perl
      # themechanger
      # google-chrome
      eza
      nixfmt
      nix-update
      keymapper
      # wemeet
      qbittorrent
      blender
      aliyunpan
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
  };
}
