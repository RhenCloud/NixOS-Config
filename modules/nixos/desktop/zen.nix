{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.zen;

  extension = shortId: guid: {
    name = guid;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "normal_installed";
    };
  };

  prefs = {
    "extensions.autoDisableScopes" = 0;
    "extensions.pocket.enabled" = false;
  };

  extensions = [
    (extension "bitwarden-password-manager" "{446900e4-71c2-419f-a6a7-df9c091e268b}")
    (extension "scriptcat" "{8e515334-52b5-4cc5-b4e8-675d50af677d}")
    (extension "immersive-translate" "{5efceaa7-f3a2-4e59-a547-85319448e305}")
  ];
in {
  options.rhencloud.zen.enable = mkEnableOption "Zen browser";

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.symlinkJoin {
        name = "zen-browser";
        paths = [
          (pkgs.wrapFirefox
            (inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped.overrideAttrs
              (_: {
                ffmpegSupport = true;
              })
            )
            {
              extraPrefs = lib.concatLines (
                lib.mapAttrsToList
                  (name: value: "lockPref(${lib.strings.toJSON name}, ${lib.strings.toJSON value});")
                  (
                    prefs
                    // {
                      "widget.wayland.text-input-v3.enabled" = true;
                    }
                  )
              );

              extraPolicies = {
                DisableTelemetry = true;
                ExtensionSettings = builtins.listToAttrs extensions;

                SearchEngines = {
                  Default = "ddg";
                  Add = [
                    {
                      Name = "nixpkgs packages";
                      URLTemplate = "https://search.nixos.org/packages?query={searchTerms}";
                      IconURL = "https://wiki.nixos.org/favicon.ico";
                      Alias = "@np";
                    }
                    {
                      Name = "NixOS options";
                      URLTemplate = "https://search.nixos.org/options?query={searchTerms}";
                      IconURL = "https://wiki.nixos.org/favicon.ico";
                      Alias = "@no";
                    }
                    {
                      Name = "NixOS Wiki";
                      URLTemplate = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
                      IconURL = "https://wiki.nixos.org/favicon.ico";
                      Alias = "@nw";
                    }
                    {
                      Name = "Homemanager Options";
                      URLTemplate = "https://home-manager-options.extranix.com/?release=master&query={searchTerms}";
                      IconURL = "https://wiki.nixos.org/favicon.ico";
                      Alias = "@ho";
                    }
                  ];
                };
              };
            }
          )
        ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          for bin in "$out"/bin/*; do
            if [ -x "$bin" ]; then
              wrapProgram "$bin" \
                --set MOZ_ENABLE_WAYLAND 1 \
                --set XMODIFIERS @im=fcitx \
                --unset GTK_IM_MODULE \
                --unset QT_IM_MODULE \
                --unset SDL_IM_MODULE \
                --unset GLFW_IM_MODULE
            fi
          done
        '';
      })
    ];
  };
}
