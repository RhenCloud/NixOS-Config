{ pkgs, ... }:
{
  users.users.rhencloud = {
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPuthZJ1ELm9QFDDUWBfzdfRZk5JE9iHOLWjU+QQTQbE cardno:FFFE_E046F201"
    ];
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "kvm"
    ];
  };
}
