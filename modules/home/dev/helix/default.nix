{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.helix;
in
{
  options.rhencloud.helix.enable = mkEnableOption "Helix editor";

  config = mkIf cfg.enable {
    home.packages = [ pkgs.helix ];

    xdg.configFile."helix/config.toml".source = ./config.toml;
    xdg.configFile."helix/languages.toml".source = ./languages.toml;
  };
}
