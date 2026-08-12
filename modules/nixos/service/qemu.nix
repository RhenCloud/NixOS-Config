{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.qemu;
in
{
  options.rhencloud.qemu.enable = mkEnableOption "QEMU virtualization";

  config = mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        qemu
        quickemu
      ];
    };
    systemd.tmpfiles.rules = [ "L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu}/share/qemu/firmware" ];
  };
}
