{ inputs, lib, ... }:
let
  h = import ./helpers.nix { inherit inputs lib; };
  systemsDir = toString "${h.root}/systems";
in
{
  flake.nixosConfigurations =
    let
      archs = lib.filterAttrs (n: t: t == "directory") (builtins.readDir systemsDir);
    in
      lib.concatMapAttrs (arch: _:
        let
          hostsDir = "${systemsDir}/${arch}";
          hostDirs = lib.filterAttrs (n: t: t == "directory") (builtins.readDir hostsDir);
        in
          lib.mapAttrs' (host: _:
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
                  ({ config, ... }: {
                    home-manager = {
                      useGlobalPkgs = false;
                      useUserPackages = true;
                      backupFileExtension = "backup";
                      extraSpecialArgs = { inherit inputs; primaryUser = config.my.user.name; };
                      users.${config.my.user.name} = {
                        imports =
                          [ "${h.root}/homes/${arch}/${config.my.user.name}@${config.my.host.name}" ]
                          ++ h.homeModules ++ h.commonHomeModules;
                      };
                    };
                    system.stateVersion = lib.mkDefault config.my.stateVersion;
                  })
                  ({ config, ... }: {
                    nixpkgs.config.allowUnfree = config.my.allowUnfree;
                    nixpkgs.config.permittedInsecurePackages = config.my.permittedInsecurePackages;
                  })
                  { nixpkgs.overlays = h.overlays; }
                ] ++ h.nixosModules;

                specialArgs = { inherit inputs; primaryUser = "rhencloud"; };
              }
            )
          ) hostDirs
      ) archs;
}