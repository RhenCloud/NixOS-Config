{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhen.packages;
in
{
  options.rhen.packages.enable = mkEnableOption "system packages";

  config = mkIf cfg.enable {
    programs.nix-ld.enable = true;

    environment.systemPackages = with pkgs; [
      bat
      cacert
      curl
      fd
      mihomo
      file
      git
      gnupg
      home-manager
      jq
      nix-direnv
      nix-du
      ntfs3g
      opensc
      pcsc-tools
      yubikey-manager
      sops
      tree
      udisks
      unzip
      usbutils
      vim
      wget
      deploy-rs
      just
    ];
  };
}
