{
  inputs,
  pkgs,
  ...
}:

{
  rhencloud.herdrPlugins.spreader = {
    id = "herdr-spreader";
    package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-spreader;
  };

  xdg.configFile."herdr-spreader/config.yaml".source = ./plugin-config.yaml;
}
