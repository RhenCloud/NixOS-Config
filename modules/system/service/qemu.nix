{ pkgs, ... }:
{
  environment = {
    systemPackages = [ pkgs.qemu ];
  };
  systemd.tmpfiles.rules = [ "L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu}/share/qemu/firmware" ];
}
