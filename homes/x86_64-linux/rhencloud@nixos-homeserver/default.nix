{ lib, ... }: {
  home.stateVersion = lib.mkDefault "26.11";
  programs.home-manager.enable = true;
  programs.man.enable = false;

  rhencloud = {
    fish.enable = true;
    herdr.enable = false;
    git = {
      enable = true;
      sshHostBlocks = false;
    };
    opencode.enable = true;
    opencode-podman.enable = true;
  };
}
