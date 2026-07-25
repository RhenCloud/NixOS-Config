{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.rhencloud.selector4nix;

  substituters = [
    {
      url = "https://cache.nixos.org/";
      priority = 40;
    }
    {
      url = "https://hyprland.cachix.org/";
      priority = 40;
    }
    {
      url = "https://nix-community.cachix.org/";
      priority = 40;
    }
    {
      url = "https://noctalia.cachix.org/";
      priority = 40;
    }
    {
      url = "https://niri.cachix.org/";
      priority = 40;
    }
    {
      url = "https://vicinae.cachix.org/";
      priority = 40;
    }
    {
      url = "https://yazi.cachix.org/";
      priority = 40;
    }
    {
      url = "https://mirrors.ustc.edu.cn/nix-channels/store/";
      priority = 45;
    }
    {
      url = "https://mirror.sjtu.edu.cn/nix-channels/store/";
      priority = 45;
    }
  ];
in {
  options.rhencloud.selector4nix.enable = mkEnableOption "selector4nix substituter";

  config = mkIf cfg.enable {
    services.selector4nix = {
      enable = true;
      configureSubstituter = "prepend";
      settings = {
        server = {
          ip = "127.0.0.1";
          port = 5496;
        };
        inherit substituters;
      };
    };
  };
}
