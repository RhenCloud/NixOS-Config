{
  inputs,
  pkgs,
  ...
}:

{
  rhencloud.herdrPlugins.mobile-relay = {
    id = "herdr-mobile-relay.events";
    package = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-mobile-relay;
  };

  home.packages = with pkgs; [
    cloudflared
  ];
}