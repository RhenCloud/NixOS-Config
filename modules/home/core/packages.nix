{
  pkgs,
  inputs,
  ...
}:
{
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
    # splayer
    ripgrep
    # 如需使用 Sequoia，可在此添加；保留系统 gnupg 可避免冲突
    # sequoia-chameleon-gnupg 提供 gpg 兼容包装器，避免同时安装 gnupg。
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
