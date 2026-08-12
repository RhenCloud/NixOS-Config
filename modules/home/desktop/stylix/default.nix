{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.hmStylix;
in
{
  options.rhencloud.hmStylix.enable = mkEnableOption "HM Stylix theme";
  config = mkIf cfg.enable {
    stylix = {
      enable = true;
      enableReleaseChecks = false;
      polarity = "dark";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
      fonts = {
        monospace = {
          name = "Maple Mono NF CN";
          package = pkgs.maple-mono.NF-CN-unhinted;
        };
        sansSerif = {
          name = "Maple Mono NF CN";
          package = pkgs.maple-mono.NF-CN-unhinted;
        };
        sizes = {
          terminal = 11;
          popups = 12;
          desktop = 12;
        };
      };
      opacity.terminal = 0.75;
      targets.foot.enable = false;
    };
  };
}
