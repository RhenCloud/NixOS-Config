{ config, lib, ... }:
let
  cfg = config.rhencloud.roles.dev;
in
{
  config = lib.mkIf cfg.enable {
    rhencloud = {
      c.enable = true;
      android.enable = true;
      golang.enable = true;
      java.enable = true;
      node.enable = true;
      python.enable = true;
      rust.enable = true;

      hmDevPackages.enable = true;
      certs.enable = true;

      opencode.enable = true;
      opencode-podman.enable = true;
      hmOpenAgent.enable = true;
      aider.enable = true;

      emacs.enable = false;
      nixvim.enable = true;
      helix.enable = true;
    };
  };
}
