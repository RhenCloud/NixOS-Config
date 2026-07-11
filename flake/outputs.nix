inputs:
let
  baseFlake = inputs.snowfall-lib.mkFlake {
    inherit inputs;
    src = ../.;

    snowfall = {
      namespace = "rhencloud";
      meta = {
        name = "nixos";
        title = "RhenCloud NixOS";
      };
    };

    "channels-config" = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-39.8.10"
        "pnpm-9.15.9"
        "pnpm-10.29.2"
      ];
    };

    homes.modules = [
      inputs.niri.homeModules.niri
      inputs.noctalia.homeModules.default
      inputs.piri.homeManagerModules.default
      inputs.nvf.homeManagerModules.default
      inputs.rime-keytao.homeManagerModules.default
      inputs.vicinae.homeManagerModules.default
      {
        nixpkgs.config.allowUnfree = true;
        nixpkgs.config.permittedInsecurePackages = [
          "electron-39.8.10"
          "pnpm-9.15.9"
          "pnpm-10.29.2"
        ];
      }
    ];

    systems.modules.nixos = [
      (
        {
          lib,
          config,
          ...
        }:
        {
          rhencloud.primaryUser = "rhencloud";
          # nixos-config = "/home/${config.rhencloud.primaryUser}/nixos";
          home-manager.useGlobalPkgs = false;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          system.stateVersion = lib.mkDefault "26.05";
        }
      )
    ];

    systems.hosts.nixos-desktop = { };
  };

  pkgsFor =
    system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ ];
    };
in
baseFlake
// {
  devShells = (baseFlake.devShells or { }) // {
    x86_64-linux = ((baseFlake.devShells or { }).x86_64-linux or { }) // {
      python = import ../shells/python.nix {
        pkgs = pkgsFor "x86_64-linux";
      };
    };
  };

  packages = (baseFlake.packages or { }) // {
    x86_64-linux = ((baseFlake.packages or { }).x86_64-linux or { }) // {
      rime-keytao = inputs.rime-keytao.packages.x86_64-linux.default;
      rimeKeytao = inputs.rime-keytao.packages.x86_64-linux.default;
      lwe =
        let
          pkgs = pkgsFor "x86_64-linux";
        in
        pkgs.callPackage ../packages/lwe/default.nix { };
      herdr-tab-rename =
        let
          pkgs = pkgsFor "x86_64-linux";
        in
        pkgs.callPackage ../packages/herdr-tab-rename/default.nix { };
      zed-globalization =
        let
          pkgs = pkgsFor "x86_64-linux";
        in
        pkgs.callPackage ../packages/zed-globalization/default.nix { };
    };
  };
}
