{ pkgs, ... }:
{
  users.users.rhencloud = {
    shell = pkgs.bash;
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
