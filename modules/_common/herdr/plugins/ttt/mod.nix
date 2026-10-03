{
  inputs,
  pkgs,
  ...
}:

{
  rhen.herdrPlugins.ttt = {
    id = "ttt.editor";
    package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.ttt-herdr-plugin;
  };
}
