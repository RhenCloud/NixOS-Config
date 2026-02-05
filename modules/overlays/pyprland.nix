{ config, pkgs, inputs, lib, ... }:
let
  cloudPyprland = inputs.cloud-pyprland.packages.${pkgs.system}.default;
in
{
  nixpkgs.overlays = [
    # (self: super: {
    #   pyprland = super.pyprland.override {
    #     pythonRelaxDeps = [ super.cloudPyprland ];
    #   };
    # }
    # )
    (self: super: {
      pyprland = super.pyprland.overridePythonAttrs (old: {
        propagatedBuildInputs =
          (old.propagatedBuildInputs or [ ])
          ++ [ cloudPyprland ];
      });
    })
  ];
}
