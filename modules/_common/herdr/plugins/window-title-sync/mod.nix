{
  inputs,
  pkgs,
  ...
}:

{
  rhen.herdrPlugins.window-title-sync = {
    id = "rjyo.window-title-sync";
    package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-window-title-sync;
  };
}
