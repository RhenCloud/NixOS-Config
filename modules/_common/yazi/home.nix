{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.yazi;

  dracula-flavor = "${inputs.yazi-flavors}/dracula.yazi";
in
{
  options.rhencloud.yazi = {
    enable = mkEnableOption "Yazi file manager";
    enableNemo = mkOption {
      type = types.bool;
      default = true;
      description = "Also enable Nemo file manager (Cinnamon desktop)";
    };
  };

  config = mkIf cfg.enable {
    # Nemo preferences via dconf
    dconf.settings = mkIf cfg.enableNemo {
      "org/nemo/preferences" = {
        default-folder-viewer = "icon-view";
        show-hidden-files = false;
        show-sidebar = true;
        use-iec-units = true;
        thumbnail-view = "local-only";
        enable-single-click = false;
        date-format = "iso";
        preferences-open-modal = false;
      };

      "org/nemo/window-state" = {
        start-with-sidebar = true;
        side-pane-width = 200;
        geometry = "1024x768+50+50";
      };

      "org/nemo/list-view" = {
        default-visible-columns = [
          "name"
          "size"
          "type"
          "date_modified"
        ];
        default-column-order = [
          "name"
          "size"
          "type"
          "date_modified"
        ];
      };
    };

    programs.yazi = {
      enable = true;
      enableFishIntegration = true;
      package = inputs.yazi.packages.${pkgs.stdenv.hostPlatform.system}.yazi;

      plugins = {
        ouch = pkgs.yaziPlugins.ouch;
        gitui = pkgs.yaziPlugins.gitui;
        smart-filter = pkgs.yaziPlugins.smart-filter;
        smart-enter = pkgs.yaziPlugins.smart-enter;
      };

      settings = {
        manager = {
          show_hidden = true;
          show_symlink = true;
          sort_by = "alphabetical";
          sort_dir_first = true;
          sort_sensitive = false;
          scrolloff = 8;
          mouse_events = [
            "click"
            "scroll"
            "touch"
          ];
          title_format = "yazi";
          tab_size = 4;
        };

        preview = {
          max_width = 600;
          max_height = 900;
          ueberzug_scale = 1;
          ueberzug_offset = [
            0
            0
            0
            0
          ];
          image_quality = 75;
          image_filter = "lanczos3";
        };

        opener = {
          edit = [
            {
              run = "$" + ''{EDITOR:-zed} "$@"'';
              block = true;
              orphan = false;
              desc = "Edit";
            }
          ];
          reveal = [
            {
              run = ''dolphin --select "$1"'';
              block = false;
              orphan = true;
              desc = "Reveal in Dolphin";
            }
          ];
          open = [
            {
              run = ''zed "$1"'';
              block = false;
              orphan = true;
              desc = "Open in Zed";
            }
          ];
        };
      };

      theme = {
        flavor.dark = "dracula";
        flavor.light = "dracula";
      };

      keymap = {
        mgr.prepend_keymap = [
          {
            on = "l";
            run = "plugin smart-enter";
            desc = "Smart enter";
          }
          {
            on = [
              "g"
              "i"
            ];
            run = "plugin gitui";
            desc = "Git UI";
          }
        ];
      };
    };

    xdg.configFile."yazi/flavors/dracula.yazi".source = dracula-flavor;

    home.packages = with pkgs; [
      bat
      chafa
      ffmpegthumbnailer
      poppler-utils
      glow
      ouch
      unar
      jq
      ripgrep
      fd
    ] ++ (optional cfg.enableNemo nemo);
  };
}
