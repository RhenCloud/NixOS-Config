{
  inputs,
  pkgs,
  ...
}:

let
  pkg = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-sidebar;
in
{
  rhencloud.herdrPlugins.herdr-sidebar = {
    id = "herdr-sidebar";
    package = pkg;
  };

  home.file = {
    ".config/herdr/plugins/herdr-sidebar/scripts".source = "${pkg}/share/herdr-sidebar/scripts";
    ".config/herdr/plugins/herdr-sidebar/target".source = "${pkg}/share/herdr-sidebar/target";
  };
}