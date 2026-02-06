{ inputs
, pkgs
, lib
, ...
}: {
  programs.zen-browser = {
    enable = true;
    profiles."default".search = {
      force = true;
      default = "google";
      engines =
        {
          nixosOptions =
            {
              name = "NixOS options";
              urls =
                {
                  template = "https://search.nixos.org/options?query={searchTerms}";
                  params = [
                    {
                      name = "query";
                      value = "searchTerms";
                    }
                  ];
                };
              icon = "https://wiki.nixos.org/favicon.ico";
              definedAliases = "@no";
            };
          nixosWiki =
            {
              name = "NixOS Wiki";
              url =
                {
                  template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
                  params = [
                    {
                      name = "query";
                      value = "searchTerms";
                    }
                  ];
                };
              icon = "https://wiki.nixos.org/favicon.ico";
              definedAliases = "@nw";
            };
        };
    };
    policies =
      let
        mkExtensionSettings = builtins.mapAttrs (_: pluginId: {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
          installation_mode = "force_installed";
        });
      in
      {
        ExtensionSettings = mkExtensionSettings {
          "{5efceaa7-f3a2-4e59-a54b-85319448e305}" = "immersive-translate";
          "adguardadblocker@adguard.com" = "adguard-adblocker";
          "{8e515334-52b5-4cc5-b4e8-675d50af677d}" = "scriptcat";
          "bewlybewlyavemujica@ventusuta.com" = "bewlybewly-avemujica";
          "{77b19bb0-313b-49c8-9e58-cef2e4ebf317}" = "smartup";
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = "bitwarden-password-manager";
        };
      };
  };
}
