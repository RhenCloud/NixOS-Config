{ pkgs, ... }:
{
  users.users.advan10 = {
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPr3U8DY69/23U+j7Y8/BdPJsGBdgufymLzZEER0/2AA advan10@siiway.org"
    ];
  };
}
