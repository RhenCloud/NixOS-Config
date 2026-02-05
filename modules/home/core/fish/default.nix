{ config
, pkgs
, lib
, ...
}:

{
  xdg.configFile = {
    "fish/init.fish" = {
      source = ./init.fish;
    };
  };

  # programs.startship = {
  #   enable = true;
  #   enableFishIntegration = true;
  # };

  programs.fish = {
    enable = true;
    shellAliases = {
      ff = "fastfetch";
      vim = "nvim";
      nrebuild = "sudo nixos-rebuild switch";
      nclean = "sudo nix-collect-garbage";
      ncleanall = "sudo nix-collect-garbage -d";
      nupgrade = "sudo nix-channel --update && sudo nixos-rebuild switch --upgrade";
    };
    # loginShellInit = "export LANG=zh_CN.UTF-8 ; export LC_ALL=zh_CN.UTF-8";
    shellInit = "set -g fish_greeting ''";
    # shellInitLast = "tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time='24-hour format' --rainbow_prompt_separators=Angled --powerline_prompt_heads=Sharp --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character' --prompt_connection=Dotted --powerline_right_prompt_frame=No --prompt_connection_andor_frame_color=Light --prompt_spacing=Sparse --icons='Many icons' --transient=Yes";
    plugins = [
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      }
      {
        name = "fzf";
        src = pkgs.fishPlugins.fzf.src;
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
    ];
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
  };

}
