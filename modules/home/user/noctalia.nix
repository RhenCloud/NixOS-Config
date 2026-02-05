{
  pkgs,
  ...
}:
{
  # imports = [
  #   inputs.noctalia.nixosModules.default
  # ];

  # programs.noctalia-shell = {
  #   enable = true;
  # };

  home.packages = with pkgs; [
    noctalia-shell
  ];
}
