{ pkgs, ... }:
{
  home.packages = with pkgs; [
    go
    gopls
    delve
    golangci-lint
    gofumpt
    golint
  ];

  home.sessionVariables = {
    GOPATH = "$HOME/.local/share/go";
    GOBIN = "$HOME/.local/share/go/bin";
  };

  home.sessionPath = [
    "$HOME/.local/share/go/bin"
  ];
}
