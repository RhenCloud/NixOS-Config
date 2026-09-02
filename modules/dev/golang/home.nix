{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.rhencloud.golang;
in
{
  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        go
        gopls
        delve
        golangci-lint
        gofumpt
        golint
      ];
      sessionVariables = {
        GOPATH = "$HOME/.local/share/go";
        GOBIN = "$HOME/.local/share/go/bin";
      };
      sessionPath = [
        "$HOME/.local/share/go/bin"
      ];
    };
  };
}
