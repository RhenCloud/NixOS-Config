{ config, lib, ... }:
{
  config = lib.mkIf config.rhen.roles.dev.enable {
    rhen = {
      c.enable = true;
      android.enable = true;
      flutter.enable = true;
      golang.enable = true;
      java.enable = true;
      node.enable = true;
      python.enable = true;
      rust.enable = true;

      hmDevPackages.enable = true;
      certs.enable = true;
      gdirect.enable = true;

      opencode.enable = true;
      hmOpenAgent.enable = true;
      aider.enable = false;
      pi.enable = true;

      emacs.enable = false;
      nixvim.enable = true;
      helix.enable = true;
    };
  };
}
