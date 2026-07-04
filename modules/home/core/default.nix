{ ... }:
{
  imports = [
    ./browser.nix
    ./git.nix
    ./obs.nix
    ./packages.nix
    ./xdg.nix
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
    "pnpm-9.15.9"
    "pnpm-10.29.2"
  ];
}
