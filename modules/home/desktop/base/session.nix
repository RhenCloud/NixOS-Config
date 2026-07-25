{ lib, config, ... }:
with lib;
let
  cfg = config.rhencloud.hmSession;
in {
  options.rhencloud.hmSession.enable = mkEnableOption "desktop session env vars";
  config = mkIf cfg.enable {
    home.sessionVariables = {
      BROWSER = config.my.browser.default;
      TERMINAL = config.my.terminal;
      EDITOR = config.my.editor;
    };
  };
}
