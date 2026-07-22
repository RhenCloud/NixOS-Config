{
  pkgs,
  ...
}:

{
  xdg.configFile."herdr/plugins/config/cloudmanic.herdr-plus/config.toml".source =
    pkgs.writeText "herdr-plus-config-toml" ''
      [worktree]
      branch_prefix = "rhencloud/"
    '';

  xdg.configFile."herdr/plugins/config/cloudmanic.herdr-plus/projects" = {
    source = ./projects;
    recursive = true;
  };

  # xdg.configFile."herdr/plugins/config/cloudmanic.herdr-plus/projects/VoidSwitch.toml".text = ''
  #   name = "voidswitch"
  #   description = "SiiWay VoidSwitch"
  #   group = "SiiWay"
  #   working_dir = "~/Project/SiiWay/VoidSwitch"

  #   [[tabs]]
  #   name = "opencode"
  #   command = "opencode"

  #   [[tabs]]
  #   name = "dev"

  #   [[tabs.panes]]
  #   label = "frontend"
  #   command = "cd ./frontend && bun run dev"

  #   [[tabs.panes]]
  #   label = "backend"
  #   command = "cd ./backend && uv run voidswitch --reload"
  #   split = "right"
  # '';
}
