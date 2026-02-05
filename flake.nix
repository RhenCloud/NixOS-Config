{
  description = "NixOS configuration";

  nixConfig = {
    substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
    trusted-substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://mirror.sjtu.edu.cn"
      "https://mirrors.ustc.edu.cn"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # home-manager, used for managing user configuration
    home-manager = {
      url = "https://gh-proxy.com/github.com/nix-community/home-manager/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      # url = "github:noctalia-dev/noctalia-shell";
      url = "https://gh-proxy.com/github.com/noctalia-dev/noctalia-shell/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "https://gh-proxy.com/github.com/hyprwm/Hyprland/archive/master.tar.gz";
    };

    cloud-pyprland = {
      url = "github:RhenCloud/cloud-pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    Hyprspace = {
      url = "github:KZDKM/Hyprspace";

      # Hyprspace uses latest Hyprland. We declare this to keep them in sync.
      inputs.hyprland.follows = "hyprland";
    };

    agenix.url = "github:ryantm/agenix";

  };

  outputs =
    inputs@{ nixpkgs
    , home-manager
    , nur
    , noctalia
    , # hyprland,
      Hyprspace
    , agenix
    , ...
    }:
    let
      username = "rhencloud";
      hostname = "nixos-desktop";
      stateVersion = "26.05";
    in
    {
      nixosConfigurations = {
        ${hostname} = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs username stateVersion; };
          modules = [
            {
              nixpkgs.hostPlatform = "x86_64-linux";
              nix.settings.trusted-users = [ username ];
            }
            ./hosts/${hostname}/configuration.nix

            nur.modules.nixos.default

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              home-manager.backupFileExtension = "backup";

              home-manager.users.${username} = {
                imports = [
                  agenix.homeManagerModules.default
                  ./modules/home
                ];
              };

              # 取消注释下面这一行，就可以在 home.nix 中使用 flake 的所有 inputs 参数了
              home-manager.extraSpecialArgs = { inherit inputs username stateVersion agenix; };
            }
          ];
        };
      };
    };
}
