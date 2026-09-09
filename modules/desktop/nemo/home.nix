{
  config,
  lib,
  ...
}:
with lib;
{
  dconf.settings = {
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
}
