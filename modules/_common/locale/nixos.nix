{ lib, config, ... }:
with lib;
let
  cfg = config.rhencloud.locale;
in
{
  options.rhencloud.locale.enable = mkEnableOption "locale configuration";
  config = mkIf cfg.enable {
    time.timeZone = "Asia/Shanghai";
    i18n.supportedLocales = [
      "zh_CN.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
    i18n.defaultLocale = "zh_CN.UTF-8";
  };
}
