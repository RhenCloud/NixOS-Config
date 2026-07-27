{
  config,
  lib,
  ...
}@args:
let
  cfg = config.rhencloud.services;
  secretsDir = "${args.inputs.self}/secrets/mihomo";
  secretProxies = builtins.readFile "${secretsDir}/proxies.yaml";
  configTemplate = builtins.readFile ./config.yaml;
  fullConfig = let
    parts = lib.splitString "# __PROXIES_HERE__" configTemplate;
  in builtins.head parts + secretProxies + builtins.elemAt parts 1;
in {
  config = lib.mkIf cfg.enable {
    environment.etc."mihomo/config.yaml".text = fullConfig;
  };
}
