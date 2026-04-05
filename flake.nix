{
  description = "NixOS configuration";

  nixConfig = {
    substituters = [
      # "https://rhencloud.cachix.org"
      "https://hyprland.cachix.org"
      # "https://nix-community.cachix.org"
      "https://noctalia.cachix.org"
      "https://niri.cachix.org"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
    trusted-substituters = [
      # "https://rhencloud.cachix.org"
      "https://hyprland.cachix.org"
      # "https://nix-community.cachix.org"
      "https://mirror.sjtu.edu.cn"
      "https://mirrors.ustc.edu.cn"
    ];
    trusted-public-keys = [
      # "rhencloud.cachix.org-1:ufAOdWG5R+cdEwikK58DG41wK6VrSVKwaSgnXxZ+D+E="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      # "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "https://gh-proxy.com/github.com/nix-community/home-manager/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nur = {
    #   url = "github:nix-community/NUR";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    noctalia = {
      # url = "github:noctalia-dev/noctalia-shell";
      url = "https://gh-proxy.com/github.com/noctalia-dev/noctalia-shell/archive/master.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # piri.url = "github:RhenCloud/piri";

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    siiway-cli = {
      url = "https://gh-proxy.com/github.com/siiway/siiway-cli/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # mango = {
    #   url = "github:DreamMaoMao/mango";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "https://gh-proxy.com/github.com/hyprwm/Hyprland/archive/master.tar.gz";
    };

    cloud-pyprland = {
      url = "github:RhenCloud/cloud-pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix.url = "github:Mic92/sops-nix";

    # agenix.url = "github:ryantm/agenix";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      # , nur
      stylix,
      niri,
      # sops-nix,
      # agenix,
      ...
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
            ./modules/overlays

            # agenix.nixosModules.default

            # nur.modules.nixos.default

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = false;
              home-manager.useUserPackages = true;

              home-manager.backupFileExtension = "backup";

              home-manager.users.${username} = {
                nixpkgs.config.allowUnfree = true;
                imports = [
                  niri.homeModules.niri
                  stylix.homeModules.stylix
                  inputs.noctalia.homeModules.default
                  # agenix.homeManagerModules.default
                  # sops-nix.homeManagerModules.sops
                  ./modules/home
                ];
              };

              home-manager.extraSpecialArgs = { inherit inputs username stateVersion; };
            }
          ];
        };
      };
    };
}
