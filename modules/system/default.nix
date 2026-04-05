{
  inputs,
  username,
  hostname,
  stateVersion,
}:
[
  {
    nixpkgs.hostPlatform = "x86_64-linux";
    nix.settings.trusted-users = [ username ];
  }
  ../../hosts/${hostname}/configuration.nix
  ../../modules/overlays

  # inputs.agenix.nixosModules.default

  # inputs.nur.modules.nixos.default

  inputs.home-manager.nixosModules.home-manager
  (import ./home-manager.nix {
    inherit inputs username stateVersion;
  })
]
