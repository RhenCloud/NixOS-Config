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
    username = config.rhen.user.name;
    homeDirectory = "/home/${config.rhen.user.name}";
  };
}
