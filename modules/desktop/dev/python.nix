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
  options.rhencloud.python.enable = mkEnableOption "Python development tools";
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
