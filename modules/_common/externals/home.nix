{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.nix-index-database.homeModules.nix-index
  ];

  home = {
    username = config.my.user.name;
    homeDirectory = "/home/${config.my.user.name}";
  };
}
