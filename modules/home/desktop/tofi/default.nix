{ ... }:

{
  xdg.configFile = {
    "tofi/config" = {
      source = ./config;
    };
  };
  programs.tofi.enable = true;
}
