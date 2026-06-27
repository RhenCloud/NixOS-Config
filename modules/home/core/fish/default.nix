{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./herdr.nix
    # ./zellij.nix  # 暂未启用，由 herdr 替代
  ];

  home.sessionVariables = {
    NIX_BUILD_SHELL = "${pkgs.fish}/bin/fish";
  };

  home.packages = with pkgs; [
    nix-output-monitor
  ];

  xdg.configFile = {
    "fish/conf.d/99-user-init.fish" = {
      source = ./init.fish;
    };
    "fish/themes/Dracula.theme".source = ./Dracula.theme;
    "starship.toml".source = config.lib.file.mkOutOfStoreSymlink ./starship.toml;
  };

  # programs.startship = {
  #   enable = true;
  #   enableFishIntegration = true;
  # };

  programs.fish = {
    enable = true;
    shellAliases = {
      nix = "nom";
      ff = "fastfetch";
      vim = "nvim";
      nrebuild = "sudo nixos-rebuild switch --log-format internal-json |& nom --json";
      hrebuild = "home-manager switch --flake .#rhencloud@nixos-desktop";
      nclean = "sudo nix-collect-garbage";
      ncleanall = "sudo nix-collect-garbage -d";
      nupgrade = "sudo nix flake update && sudo nixos-rebuild switch --upgrade --log-format internal-json |& nom --json";
      tree = "tree --gitignore -I '.git'";
      oc = "opencode";
    };
    # loginShellInit = "export LANG=zh_CN.UTF-8 ; export LC_ALL=zh_CN.UTF-8";
    shellInit = "set -g fish_greeting ''";
    # shellInitLast = "tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time='24-hour format' --rainbow_prompt_separators=Angled --powerline_prompt_heads=Sharp --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character' --prompt_connection=Dotted --powerline_right_prompt_frame=No --prompt_connection_andor_frame_color=Light --prompt_spacing=Sparse --icons='Many icons' --transient=Yes";
    # functions = {
    # magic-enter-cmd = {

    #   body = ''
    #     # Default magic command.
    #     set --local my_magic_command 'ls'

    #     # Git dir magic command.
    #     if command git rev-parse --is-inside-work-tree &>/dev/null
    #       set my_magic_command "git status"
    #     end

    #     if command ls pyproject.toml &>/dev/null && command uv &>/dev/null
    #       set my_magic_command "uv sync"
    #     end

    #     if command ls flake.nix &>/dev/null
    #       set my_magic_command "nix flake update"
    #     end

    #     eval $my_magic_command
    #   '';
    # };
    # };
    plugins = [
      # {
      #   name = "z";
      #   src = pkgs.fishPlugins.z.src;
      # }
      {
        name = "fzf";
        src = pkgs.fishPlugins.fzf.src;
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
      {
        name = "async-prompt";
        src = pkgs.fishPlugins.async-prompt.src;
      }
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
      # {
      #   name = "tide";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "IlanCosman";
      #     repo = "tide";
      #     rev = "main";
      #     sha256 = "sha256-dzYEYC1bYP0rWpmz0fmBFwskxWYuKBMTssMELXXz5H0=";
      #   };
      # }
      # {
      #   name = "pure";
      #   src = pkgs.fishPlugins.pure.src;
      # }
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

  programs.starship = {
    enable = false;
    enableFishIntegration = true;
    # settings = {
    #   add_newline = false;
    #   format = "$username$directory$git_branch\n$character";
    #   right_format = "$cmd_duration $hostname";
    #   username = {
    #     show_always = true;
    #   };
    #   directory = {
    #     truncate_to_repo = false;
    #   };
    #   cmd_duration = {
    #     min_time = 0;
    #     format = "took [$duration]($style)";
    #   };
    #   hostname = {
    #     format = "on [$hostname]($style)";
    #   };
    # };
  };

  programs.superfile = {
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
      shell_close_on_success = false;
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

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    icons = "always";
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

}
