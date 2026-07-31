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
      lib.concatMapAttrs (arch: _:
        let
          userDirs = lib.filterAttrs (_n: t: t == "directory")
            (builtins.readDir "${homesDir}/${arch}");
        in
          lib.mapAttrs' (userEntry: _:
            lib.nameValuePair userEntry (
              let
                pkgs = import inputs.nixpkgs {
                  localSystem = { system = arch; };
                  config.allowUnfree = true;
                  overlays = h.overlays;
                };
              in
              inputs.home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                modules = [ "${homesDir}/${arch}/${userEntry}" ]
                  ++ h.homeModules ++ h.essentialHomeModules;
                extraSpecialArgs = { inherit inputs; primaryUser = "rhencloud"; };
              }
            )
          ) userDirs
      ) archs;
}