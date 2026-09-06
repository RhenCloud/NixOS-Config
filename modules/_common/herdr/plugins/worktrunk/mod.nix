{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  pkg = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-worktrunk;
  scriptNames = [
    "config.sh"
    "helpers.sh"
    "lifecycle.sh"
    "merge.sh"
    "open.sh"
    "picker.sh"
    "remove.sh"
  ];
in
{
  rhencloud.herdrPlugins.worktrunk = {
    id = "worktrunk";
    package = pkg;
  };

  home.packages = [ pkgs.worktrunk ];

  home.file = lib.listToAttrs (
    map (name: {
      name = ".config/herdr/plugins/worktrunk/${name}";
      value.source = "${pkg}/share/worktrunk/${name}";
    }) scriptNames
  );

  xdg.configFile."herdr/plugins/config/worktrunk/config.toml".text = ''
    open_mode = "workspace"
  '';
}
