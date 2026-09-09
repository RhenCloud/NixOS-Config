{
  config,
  lib,
  inputs,
  snowveil,
  ...
}:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.nix-index-database.homeModules.nix-index
  ];

  sops.defaultSopsFile = snowveil.sops.commonFile;

  home = {
    username = config.my.user.name;
    homeDirectory = "/home/${config.my.user.name}";
  };
}
