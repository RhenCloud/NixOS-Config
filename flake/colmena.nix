{ inputs, lib, ... }:
let
  h = import ./helpers.nix { inherit inputs lib; };
in
{
  flake.colmenaHive = inputs.colmena.lib.makeHive {
    meta = {
      nixpkgs = import inputs.nixpkgs {
        localSystem = {
          system = "x86_64-linux";
        };
        config.allowUnfree = true;
        inherit (h) overlays;
      };
      specialArgs = {
        inherit inputs;
        primaryUser = "rhencloud";
      };
    };

    defaults = { config, lib, ... }: {
      imports =
        h.nixosModules
        ++ [ h.optionsModule ]
        ++ [
          inputs.impermanence.nixosModules.impermanence
          inputs.selector4nix.nixosModules.selector4nix
          inputs.mangowm.nixosModules.mango
          inputs.sops-nix.nixosModules.sops
          { sops.useSystemdActivation = true; }
        ];

      nixpkgs.overlays = h.overlays;
      nixpkgs.config.allowUnfree = config.my.allowUnfree;
      nixpkgs.config.permittedInsecurePackages = config.my.permittedInsecurePackages;
      system.stateVersion = lib.mkDefault config.my.stateVersion;
    };

    nixos-desktop = { ... }: {
      deployment.targetHost = null;
      deployment.allowLocalDeployment = true;

      imports = [ "${inputs.self}/systems/x86_64-linux/nixos-desktop" ];
    };

    yc-hk-1 = { ... }: {
      deployment.targetHost = "83.229.127.169";
      deployment.targetPort = 45855;
      # deployment.buildOnTarget = true;

      deployment.tags = [
        "siiway"
        "server"
        "hk"
      ];

      imports = [ "${inputs.self}/systems/x86_64-linux/yc-hk-1" ];
    };
  };
}
