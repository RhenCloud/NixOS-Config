{ pkgs, ... }:
{
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
}
