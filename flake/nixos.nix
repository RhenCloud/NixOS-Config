{ inputs, lib, ... }:
let
  h = import ./helpers.nix { inherit inputs lib; };
  systemsDir = toString "${h.root}/systems";
in
{
  flake.nixosConfigurations =
    let
      archs = lib.filterAttrs (_n: t: t == "directory") (builtins.readDir systemsDir);
    in
    lib.concatMapAttrs (
      arch: _:
      let
        hostsDir = "${systemsDir}/${arch}";
        hostDirs = lib.filterAttrs (_n: t: t == "directory") (builtins.readDir hostsDir);
      in
      lib.mapAttrs' (
        host: _:
        lib.nameValuePair host (
          inputs.nixpkgs.lib.nixosSystem {
            system = arch;
            modules = [
              h.optionsModule
              "${hostsDir}/${host}"
              inputs.mangowm.nixosModules.mango
              inputs.selector4nix.nixosModules.selector4nix
              inputs.home-manager.nixosModules.home-manager
              inputs.impermanence.nixosModules.impermanence
              inputs.sops-nix.nixosModules.sops
              inputs.fast-nix-gc.nixosModules.default
              ({ config, ... }: { sops.useSystemdActivation = true; })
              ({ config, ... }: {
                home-manager = lib.mkIf config.my.homeManager.enable {
                  useGlobalPkgs = false;
                  useUserPackages = true;
                  backupFileExtension = "backup";
                  extraSpecialArgs = {
                    inherit inputs;
                    primaryUser = config.my.user.name;
                  };
                  users.${config.my.user.name} = {
                    nixpkgs.overlays = h.overlays;
                    imports = [
                      "${h.root}/homes/${arch}/${config.my.user.name}@${config.my.host.name}"
                    ]
                    ++ h.homeModules
                    ++ h.essentialHomeModules
                    ++ lib.optionals config.my.isDesktop h.desktopHomeModulesFull;
                  };
                };
                system.stateVersion = lib.mkDefault config.my.stateVersion;
              })
              ({ config, ... }: {
                nixpkgs.config.allowUnfree = config.my.allowUnfree;
                nixpkgs.config.permittedInsecurePackages = config.my.permittedInsecurePackages;
              })
              { nixpkgs.overlays = h.overlays; }
            ]
            ++ h.nixosModules;

            specialArgs = { inherit inputs; };
          }
        )
      ) hostDirs
    ) archs;
}
