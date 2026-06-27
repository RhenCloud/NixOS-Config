{ inputs, config, ... }:
{
  imports = [ inputs.aagl.nixosModules.default ];

  nix.settings = inputs.aagl.nixConfig // {
    trusted-users = [ config.rhencloud.primaryUser ];
  };

  programs.anime-game-launcher.enable = false;
  # programs.anime-games-launcher.enable = true;
}
