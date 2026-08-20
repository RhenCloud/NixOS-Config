{ inputs, lib, ... }:
let
  h = import ./helpers.nix { inherit inputs lib; };
  homesDir = toString "${h.root}/homes";
in
{
  flake.homeConfigurations =
    let
      archs = lib.filterAttrs (_n: t: t == "directory") (builtins.readDir homesDir);
    in
    lib.concatMapAttrs (
      arch: _:
      let
        userDirs = lib.filterAttrs (_n: t: t == "directory") (builtins.readDir "${homesDir}/${arch}");
        pkgs = import inputs.nixpkgs {
          localSystem = {
            system = arch;
          };
          config.allowUnfree = true;
          config.permittedInsecurePackages = [
            "electron-39.8.10"
            "pnpm-9.15.9"
            "pnpm-10.29.2"
          ];
          overlays = h.overlays;
        };
      in
      lib.mapAttrs' (
        userEntry: _:
        lib.nameValuePair userEntry (
          inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              "${homesDir}/${arch}/${userEntry}"
            ]
            ++ h.homeModules
            ++ h.essentialHomeModules
            ++ lib.optionals (builtins.elem (lib.last (lib.splitString "@" userEntry)) h.desktopHosts) h.desktopHomeModulesFull;
            extraSpecialArgs = {
              inherit inputs;
              primaryUser = "rhencloud";
            };
          }
        )
      ) userDirs
    ) archs;
}
