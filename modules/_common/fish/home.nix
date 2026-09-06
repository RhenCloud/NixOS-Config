{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.rhencloud.fish;
in
{
  options.rhencloud.fish.enable = mkEnableOption "Fish shell";

  config = mkIf cfg.enable {
    home.sessionVariables = {
      NIX_BUILD_SHELL = "${pkgs.fish}/bin/fish";
      SHELL = "${pkgs.fish}/bin/fish";
      PKG_CONFIG_PATH = "${pkgs.libffi.dev}/lib/pkgconfig:${pkgs.zlib.dev}/lib/pkgconfig:${pkgs.libpng.dev}/lib/pkgconfig:${
        pkgs.lib.concatStringsSep ":" (
          map (p: "${p.dev or p}/lib/pkgconfig") (
            with pkgs;
            [
              libjpeg_turbo
              openssl
              libxml2
            ]
          )
        )
      }:$PKG_CONFIG_PATH";
    };

    home.packages = with pkgs; [
      nix-output-monitor
    ];

    xdg.configFile = {
      "fish/conf.d/99-user-init.fish" = {
        source = ./init.fish;
      };
      "fish/themes/Dracula.theme".source = ./Dracula.theme;
    };

    programs = {
      fish = {
        enable = true;
        shellAliases = {
          tokei = "tokei --sort code";
          ff = "fastfetch";
          vim = "nvim";
          tree = "tree --gitignore -I '.git'";
          oc = "opencode --auto";
          opencode = "opencode --auto";
        };
        shellInit = "set -g fish_greeting ''";
        functions = {
          nrun = {
            body = ''
              if test (count $argv) -eq 0
                  echo "Usage: nrun <package>"
                  return 1
              end
              nix run nixpkgs#$argv[1]
            '';
          };
          vm = {
            description = "用 nixos-shell 启动 tmpfs 测试 VM";
            body = ''
              set -l flake /home/rhencloud/Project/NixOS-Config
              if test (count $argv) -gt 0
                nix run $flake#vm -- $argv
              else
                nix run $flake#vm
              end
            '';
          };
          sandbox = {
            description = "在 bubblewrap + tmpfs 沙箱中运行命令，测试不落盘";
            body = ''
              set -l flake /home/rhencloud/Project/NixOS-Config
              nix run $flake#sandbox -- $argv
            '';
          };
        };
        plugins = [
          {
            name = "fzf";
            src = pkgs.fishPlugins.fzf.src;
          }
          {
            name = "autopair";
            src = pkgs.fishPlugins.autopair.src;
          }
          {
            name = "forgit";
            src = pkgs.fishPlugins.forgit.src;
          }
          {
            name = "tide";
            src = pkgs.fishPlugins.tide.src;
          }
          {
            name = "fish-you-should-use";
            src = pkgs.fishPlugins.fish-you-should-use.src;
          }
          {
            name = "sudope";
            src = pkgs.fishPlugins.plugin-sudope.src;
          }
          {
            name = "sponge";
            src = pkgs.fishPlugins.sponge.src;
          }
          {
            name = "dracula";
            src = pkgs.fetchFromGitHub {
              owner = "dracula";
              repo = "fish";
              rev = "master";
              sha256 = "sha256-Hyq4EfSmWmxwCYhp3O8agr7VWFAflcUe8BUKh50fNfY=";
            };
          }
          {
            name = "magic-enter";
            src = pkgs.fetchFromGitHub {
              owner = "mattmc3";
              repo = "magic-enter.fish";
              rev = "main";
              sha256 = "sha256-zDrc2d2VTeTiukRLeezlbj06ICr0AJId/iJx11xPKyo=";
            };
          }
        ];
      };
      superfile = {
        enable = true;
        settings = {
          theme = "Dracula";
          editor = "code";
          dir_editor = "";
          auto_check_update = false;
          cd_on_quit = false;
          default_open_file_preview = true;
          show_image_preview = true;
          show_panel_footer_info = true;
          default_directory = ".";
          file_size_use_si = true;
          default_sort_type = 0;
          sort_order_reversed = false;
          case_sensitive_sort = false;
          page_scroll_size = 0;
          ignore_missing_fields = true;
          code_previewer = "bat";
          nerdfont = true;
          transparent_background = true;
          metadata = true;
          zoxide_support = true;
          openwith = {
            "png" = "gwenview";
            "jpg" = "gwenview";
          };
        };
      };
      zoxide = {
        enable = true;
        enableFishIntegration = true;
      };
      eza = {
        enable = true;
        enableFishIntegration = true;
        icons = "always";
      };
      fzf = {
        enable = true;
        enableFishIntegration = true;
      };
      direnv = {
        enable = true;
        enableFishIntegration = true;
        nix-direnv.enable = true;
      };
      nix-index = {
        enable = true;
        enableFishIntegration = true;
        symlinkToCacheHome = true;
      };
      nix-index-database.comma.enable = true;
    };

    services.lorri = {
      enable = false;
    };
  };
}
