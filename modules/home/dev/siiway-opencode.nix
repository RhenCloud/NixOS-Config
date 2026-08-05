{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhencloud.opencode;
in
{
  options.rhencloud.opencode.enable = mkEnableOption "opencode AI assistant";
  config = mkIf cfg.enable {
    xdg.configFile."opencode/opencode.json".source =
      config.lib.file.mkOutOfStoreSymlink "/run/secrets/rendered/opencode.json";
  };
}
