{ lib, config, ... }:
with lib;
let
  cfg = config.rhencloud.vicinae;
in
{
  options.rhencloud.vicinae.enable = mkEnableOption "Vicinae app launcher";
  config = mkIf cfg.enable {
    programs.vicinae = {
      enable = false;

      systemd = {
        enable = true;
        autoStart = true;
        environment = {
          USE_LAYER_SHELL = "1";
        };
      };

      settings = {
        close_on_focus_loss = true;
        consider_preedit = true;
        pop_to_root_on_close = true;
        favicon_service = "twenty";
        search_files_in_root = true;

        font.normal = {
          size = 14;
          family = "Maple Mono NF CN";
        };

        launcher_window.opacity = 0.97;

        theme = {
          light = {
            name = "vicinae-light";
            icon_theme = "default";
          };
          dark = {
            name = "vicinae-dark";
            icon_theme = "default";
          };
        };
      };
    };
  };
}
