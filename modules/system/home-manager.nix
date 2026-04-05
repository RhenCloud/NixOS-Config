{
  inputs,
  username,
  stateVersion,
}:
let
  hasPiriHomeModule = inputs.piri ? homeManagerModules && inputs.piri.homeManagerModules ? default;
in
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
      inputs.piri.homeManagerModules.default
      ../../modules/home
    ];
  };

  home-manager.extraSpecialArgs = {
    inherit
      inputs
      username
      stateVersion
      hasPiriHomeModule
      ;
  };
}
