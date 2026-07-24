{
  inputs,
  pkgs,
  ...
}:

{
  rhencloud.herdrPlugins.herdr-plus = {
    id = "cloudmanic.herdr-plus";
    package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-plus;
  };

  xdg.configFile."herdr/plugins/config/cloudmanic.herdr-plus/config.toml".source =
    pkgs.writeText "herdr-plus-config-toml" ''
      [worktree]
      branch_prefix = "rhencloud/"
    '';

  xdg.configFile."herdr/plugins/config/cloudmanic.herdr-plus/projects" = {
    source = ./projects;
    recursive = true;
  };
}
