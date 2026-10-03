{ lib, config, ... }:
with lib;
let
  cfg = config.rhen.hmSession;
in
{
  options.rhen.hmSession.enable = mkEnableOption "desktop session env vars";
  config = mkIf cfg.enable {
    home.sessionVariables = {
      BROWSER = config.rhen.browser.default;
      TERMINAL = config.rhen.terminal;
      EDITOR = config.rhen.editor;
    };
  };
}
