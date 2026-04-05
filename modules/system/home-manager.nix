{
  inputs,
  username,
  stateVersion,
}:
{
  home-manager.useGlobalPkgs = false;
  home-manager.useUserPackages = true;

  home-manager.backupFileExtension = "backup";

  home-manager.users.${username} = {
    nixpkgs.config.allowUnfree = true;
    imports = [
      inputs.niri.homeModules.niri
      inputs.stylix.homeModules.stylix
      inputs.noctalia.homeModules.default
      # inputs.agenix.homeManagerModules.default
      # inputs.sops-nix.homeManagerModules.sops
      ../../modules/home
    ];
  };

  home-manager.extraSpecialArgs = { inherit inputs username stateVersion; };
}
