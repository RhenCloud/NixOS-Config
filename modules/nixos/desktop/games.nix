{ inputs, primaryUser, ... }:
{
  imports = [ inputs.aagl.nixosModules.default ];

  nix.settings = inputs.aagl.nixConfig // {
    trusted-users = [ primaryUser ];
  };

  programs.anime-game-launcher.enable = false;
  # programs.anime-games-launcher.enable = true;
}
