{
  inputs,
  pkgs,
  ...
}:

let
  pkg = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-reviewr;
in
{
  rhencloud.herdrPlugins."persiyanov.reviewr" = {
    id = "persiyanov.reviewr";
    package = pkg;
  };

  home.file = {
    ".config/herdr/plugins/persiyanov.reviewr/herdr".source = "${pkg}/share/persiyanov.reviewr/herdr";
    ".config/herdr/plugins/persiyanov.reviewr/bin".source = "${pkg}/share/persiyanov.reviewr/bin";
  };
}
