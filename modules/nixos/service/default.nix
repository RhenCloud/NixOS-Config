{ ... }:
{
  imports = [
    ./bluetooth.nix
    ./docker.nix
    ./display-managers.nix
    ./easytier.nix
    ./podman.nix
    ./selector4nix.nix
    ./sound.nix
    ./cloudflared.nix
    ./qemu.nix
  ];
}
