{ pkgs, ... }:
{
  users.users.wyf9 = {
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFIma5iDdPnEdjYbj7epS/ogQaJmWAvWm8jnXgvU10x wyf9@wyf9Desktop"
    ];
  };
}
