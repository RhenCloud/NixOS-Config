{
  config,
  lib,
  ...
}@args:
let
  cfg = config.rhencloud.services;
  secretsDir = "${args.inputs.self}/secrets/mihomo";
in {
  config = lib.mkIf cfg.enable {
    environment.etc = {
      "mihomo/config.yaml".source = ./config.yaml;
      "mihomo/proxies/manual.yaml".text = builtins.readFile "${secretsDir}/proxies.yaml";
    };
  };
}
