{ config, lib, inputs, primaryUser, ... }:
with lib;
let cfg = config.rhencloud.games;
in {
  options.rhencloud.games.enable = mkEnableOption "gaming support (AAGL)";

  imports = [ inputs.aagl.nixosModules.default ];

  config = mkIf cfg.enable {
    nix.settings = inputs.aagl.nixConfig // {
      trusted-users = [ primaryUser ];
    };

    programs.anime-game-launcher.enable = false;
  };
}
