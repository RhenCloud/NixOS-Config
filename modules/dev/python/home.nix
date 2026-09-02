{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.python;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      python315
      prek
      ruff
      libffi.dev
      # python311
    ];

    programs.uv = {
      enable = true;
      settings = {
        system-certs = true;
        index = [ { url = "https://pypi.org/simpl"; } ];
      };
    };
  };
}
